#!/usr/bin/env python3
# Version: 0.45.0
# Created: Petr Krivan
# Project: android lab manager
import html
import json
import os
import re
import subprocess
import sys
import time
import uuid
from pathlib import Path
from flask import Flask, request, Response

LAB_HOME = Path(os.environ.get('LAB_HOME', str(Path.home() / 'AndroidLab' / 'android-podman-lab')))
RECORDS = LAB_HOME / 'config' / 'instances.tsv'
API_CACHE = LAB_HOME / 'config' / 'api-list.txt'
DEVICE_CACHE = LAB_HOME / 'config' / 'device-list.txt'
UPLOADS = LAB_HOME / 'uploads'
JOBS = LAB_HOME / 'config' / 'jobs'
UPLOADS.mkdir(parents=True, exist_ok=True)
JOBS.mkdir(parents=True, exist_ok=True)
HOST = os.environ.get('MANAGER_HOST', '127.0.0.1')
PORT = int(os.environ.get('MANAGER_PORT', '18080'))
PUBLIC_HOST = os.environ.get('PUBLIC_HOST', '')
TOKEN = os.environ.get('MANAGER_TOKEN', '')
CSRF_TOKEN = os.environ.get('MANAGER_CSRF_TOKEN', TOKEN)
NAME_RE = re.compile(r'^[a-zA-Z0-9_-]+$')

try:
    from definitions import API_PRESETS, NOVNC_PROFILES, NOVNC_PROFILE_LABELS, DEVICE_PROFILES
except ImportError:  # pragma: no cover - supports package-style imports in tests/tools
    from .definitions import API_PRESETS, NOVNC_PROFILES, NOVNC_PROFILE_LABELS, DEVICE_PROFILES

app = Flask(__name__)


def render_ui_template(template_name, **ctx):
    """Render manager templates without tying regression tests to Flask/Jinja internals."""
    template_path = Path(__file__).parent / 'templates' / template_name
    text = template_path.read_text(errors='replace')
    text = text.replace("{{ url_for('static', filename='app.css') }}", '/static/app.css')
    text = text.replace("{{ url_for('static', filename='app.js') }}", '/static/app.js')
    for key, value in ctx.items():
        raw = '' if value is None else str(value)
        escaped = html.escape(raw)
        text = text.replace('{{ ' + key + '|safe }}', raw)
        text = text.replace('{{ ' + key + '|e }}', escaped)
        text = text.replace('{{ ' + key + ' }}', escaped)
    return text


def require_auth():
    if not TOKEN:
        return None
    auth = request.authorization
    if auth and auth.password == TOKEN:
        return None
    return Response('Authentication required', 401, {'WWW-Authenticate': 'Basic realm=AndroidLab'})


@app.before_request
def auth_gate():
    auth_resp = require_auth()
    if auth_resp:
        return auth_resp
    if request.method == 'POST' and CSRF_TOKEN:
        if request.form.get('csrf') != CSRF_TOKEN:
            return Response('Invalid CSRF token', 403)
    return None


def run_result(args, env_extra=None):
    env = os.environ.copy()
    if env_extra:
        env.update({k: v for k, v in env_extra.items() if v is not None})
    p = subprocess.run([str(LAB_HOME / 'androidlab.sh')] + args, cwd=LAB_HOME, text=True, capture_output=True, env=env)
    text = p.stdout + p.stderr
    if p.returncode != 0:
        text += f"\n[exit code {p.returncode}]"
    return text, p.returncode


def run(args, env_extra=None):
    text, _ = run_result(args, env_extra)
    return text


def start_background_job(title, steps):
    JOBS.mkdir(parents=True, exist_ok=True)
    job_id = time.strftime('%Y%m%d-%H%M%S-') + uuid.uuid4().hex[:8]
    log_path = JOBS / f'{job_id}.log'
    status_path = JOBS / f'{job_id}.status'
    cfg_path = JOBS / f'{job_id}.json'
    log_path.write_text('[+] Queued job\n')
    status_path.write_text('queued')
    cfg = {
        'job_id': job_id,
        'title': title,
        'lab_home': str(LAB_HOME),
        'log_path': str(log_path),
        'status_path': str(status_path),
        'steps': steps,
    }
    cfg_path.write_text(json.dumps(cfg, indent=2))
    env = os.environ.copy()
    env['LAB_HOME'] = str(LAB_HOME)
    subprocess.Popen(
        [sys.executable, str(LAB_HOME / 'manager' / 'job_runner.py'), str(cfg_path)],
        cwd=LAB_HOME,
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    return job_id


def job_page(job_id, title='Background job'):
    return page(render_ui_template('job.html', job_id=job_id, title=title))



def pod_state(name):
    if not NAME_RE.match(name or ''):
        return 'invalid'
    try:
        p = subprocess.run(['podman', 'pod', 'inspect', name, '--format', '{{.State}}'], text=True, capture_output=True, timeout=4)
    except Exception:
        return 'unknown'
    if p.returncode != 0:
        return 'missing'
    state = (p.stdout or '').strip()
    return state or 'unknown'


def state_badge(state):
    cls = 'status-unknown'
    if state in ('Running', 'running'):
        cls = 'status-running'
    elif state in ('Exited', 'Stopped', 'Created', 'Paused', 'exited', 'stopped'):
        cls = 'status-stopped'
    elif state == 'missing':
        cls = 'status-missing'
    return f"<span class='status-badge {cls}'>{html.escape(state)}</span>"


def parse_record(line, line_no=0):
    """Parse current and older instances.tsv formats.

    Current v31: name mode adb novnc api target created device cpu ram heap partition
    v25-v30:     name mode adb novnc api target created device
    v7-v24:      name mode adb novnc api target created
    legacy:      name mode adb api target created
    """
    p = line.rstrip('\n').split('\t')
    if not p or not p[0].strip():
        return None, None
    warn = None
    if len(p) >= 12:
        name, mode, adb, novnc, api, target, created, device, cpu, ram, heap, partition = (p + [''] * 12)[:12]
    elif len(p) >= 8:
        name, mode, adb, novnc, api, target, created, device = (p + [''] * 8)[:8]
        cpu, ram, heap, partition = '2', '4096', '512', '4096'
    elif len(p) >= 7:
        name, mode, adb, novnc, api, target, created = (p + [''] * 7)[:7]
        device = 'pixel'
        cpu, ram, heap, partition = '2', '4096', '512', '4096'
    elif len(p) == 6:
        name, mode, adb, api, target, created = p
        novnc = ''
        device = 'pixel'
        cpu, ram, heap, partition = '2', '4096', '512', '4096'
        warn = f'old 6-column record normalized: {name} line {line_no}'
    else:
        name = p[0] if len(p) > 0 else ''
        mode = p[1] if len(p) > 1 else 'headless'
        adb = p[2] if len(p) > 2 else ''
        novnc = ''
        api = p[3] if len(p) > 3 else '33'
        target = p[4] if len(p) > 4 else 'google_apis'
        created = p[5] if len(p) > 5 else ''
        device = 'pixel'
        cpu, ram, heap, partition = '2', '4096', '512', '4096'
        warn = f'malformed record normalized: {name or "unknown"} line {line_no}'
    mode = mode or 'headless'
    api = api or '33'
    target = target or 'google_apis'
    if mode != 'novnc':
        novnc = ''
    device = device or 'pixel'
    cpu = cpu or '2'; ram = ram or '4096'; heap = heap or '512'; partition = partition or '4096'
    return dict(name=name, mode=mode, adb=adb, novnc=novnc, api=api, target=target, created=created,
                device=device, cpu=cpu, ram=ram, heap=heap, partition=partition), warn

def rows():
    out = []
    seen_name = set()
    seen_ports = set()
    warnings = []
    if RECORDS.exists():
        for line_no, line in enumerate(RECORDS.read_text().splitlines(), 1):
            if not line.strip():
                continue
            r, warn = parse_record(line, line_no)
            if warn:
                warnings.append(warn)
            if not r:
                continue
            name = r['name']
            adb = r['adb']
            novnc = r['novnc']
            if name in seen_name:
                warnings.append(f'duplicate name ignored on page: {name} line {line_no}')
                continue
            if adb and adb in seen_ports:
                warnings.append(f'duplicate port ignored on page: {adb} line {line_no}')
                continue
            if novnc and novnc in seen_ports:
                warnings.append(f'duplicate port ignored on page: {novnc} line {line_no}')
                continue
            seen_name.add(name)
            if adb:
                seen_ports.add(adb)
            if novnc:
                seen_ports.add(novnc)
            out.append(r)
    return out, warnings


def api_options():
    items = []
    if API_CACHE.exists():
        for line in API_CACHE.read_text().splitlines():
            m = re.search(r'system-images;android-(\d+);([^;]+);x86_64', line)
            if m:
                items.append((m.group(1), m.group(2), line.strip()))
    return sorted(set(items), key=lambda x: (int(x[0]), x[1]))



def device_options():
    items = []
    if DEVICE_CACHE.exists():
        for line in DEVICE_CACHE.read_text(errors='replace').splitlines():
            if not line.strip() or '\t' not in line:
                continue
            device, label = line.split('\t', 1)
            if valid_device_profile(device):
                items.append((device, label.strip() or device))
    # Built-in fallback/presets stay visible even before refresh.
    seen = {d for d, _ in items}
    for d, label in DEVICE_PROFILES:
        if d not in seen:
            items.append((d, label))
    return items

def preset_options(default='33|google_apis'):
    opts = []
    for api, label, codename, target, note in API_PRESETS:
        value = f'{api}|{target}'
        text = f'{label} / API {api} / {target} — {note}'
        opts.append(f"<option value='{html.escape(value)}' {'selected' if value == default else ''}>{html.escape(text)}</option>")
    return ''.join(opts)


def novnc_profile_options(default='normal'):
    return ''.join(
        f"<option value='{html.escape(k)}' {'selected' if k == default else ''}>{html.escape(NOVNC_PROFILE_LABELS[k])}</option>"
        for k in NOVNC_PROFILE_LABELS
    )




def device_profile_options(default='pixel'):
    return ''.join(
        f"<option value='{html.escape(value)}' {'selected' if value == default else ''}>{html.escape(label)} — {html.escape(value)}</option>"
        for value, label in device_options()
    )


def parse_device_profile(form):
    custom = form.get('device_custom', '').strip()
    device = custom or form.get('device_profile', 'pixel')
    return device or 'pixel'


def valid_device_profile(device):
    return re.match(r'^[a-zA-Z0-9_.-]+$', device or '') is not None and len(device or '') <= 64

def novnc_env_from_form(form):
    profile = form.get('novnc_profile', 'normal')
    screen, skin, scale = NOVNC_PROFILES.get(profile, NOVNC_PROFILES['normal'])
    return {'NOVNC_SCREEN': screen, 'EMULATOR_SKIN': skin, 'EMULATOR_SCALE': scale}


def parse_api_target(form):
    preset = form.get('preset', '33|google_apis')
    api, target = '33', 'google_apis'
    if '|' in preset:
        api, target = preset.split('|', 1)
    api_override = form.get('api', '').strip()
    target_override = form.get('target', '').strip()
    if api_override:
        api = api_override
    if target_override:
        target = target_override
    return api, target


def valid_mode(mode):
    return mode in ('headless', 'novnc')


def valid_api_target(api, target):
    return re.match(r'^[0-9]{2,3}$', api or '') and target in ('google_apis', 'google_apis_playstore')


def image_name(api, target, mode='headless'):
    repo = 'android-emulator-novnc' if mode == 'novnc' else 'android-emulator-headless'
    return f'localhost/{repo}:api{api}-{target}-x86_64'


def image_exists(api, target, mode='headless'):
    try:
        return subprocess.run(['podman', 'image', 'exists', image_name(api, target, mode)], text=True, capture_output=True, timeout=5).returncode == 0
    except Exception:
        return False


def back(section='overview', label=None):
    section = section if section in ('overview', 'spawn', 'profiles', 'instances', 'frida') else 'overview'
    label = label or f'Back to {section.title()}'
    return f"<a class='button-link' href='/?view={html.escape(section)}#{html.escape(section)}'>{html.escape(label)}</a>"


def merge_env(*dicts):
    out = {}
    for d in dicts:
        if d:
            out.update({k: v for k, v in d.items() if v is not None})
    return out


def parse_hw_profile(form, defaults=None):
    defaults = defaults or {}
    return {
        'CPU_CORES': (form.get('cpu_cores') or defaults.get('CPU_CORES') or '2').strip(),
        'RAM_MB': (form.get('ram_mb') or defaults.get('RAM_MB') or '4096').strip(),
        'VM_HEAP_MB': (form.get('vm_heap_mb') or defaults.get('VM_HEAP_MB') or '512').strip(),
        'PARTITION_SIZE': (form.get('partition_size') or defaults.get('PARTITION_SIZE') or '4096').strip(),
    }


def valid_hw_profile(hw):
    try:
        cpu = int(hw.get('CPU_CORES', '2'))
        ram = int(hw.get('RAM_MB', '4096'))
        heap = int(hw.get('VM_HEAP_MB', '512'))
        part = int(hw.get('PARTITION_SIZE', '4096'))
    except Exception:
        return False
    return 1 <= cpu <= 16 and 512 <= ram <= 65536 and 64 <= heap <= 8192 and 1024 <= part <= 131072


def hw_inputs(values=None):
    values = values or {}
    cpu = html.escape(str(values.get('CPU_CORES') or values.get('cpu') or '2'))
    ram = html.escape(str(values.get('RAM_MB') or values.get('ram') or '4096'))
    heap = html.escape(str(values.get('VM_HEAP_MB') or values.get('heap') or '512'))
    part = html.escape(str(values.get('PARTITION_SIZE') or values.get('partition') or '4096'))
    return ("<div class='form-row hw-row'>"
            "CPU cores <input data-testid='hw-cpu-cores' name='cpu_cores' value='" + cpu + "' size='4'> "
            "RAM MB <input data-testid='hw-ram-mb' name='ram_mb' value='" + ram + "' size='7'> "
            "VM heap MB <input data-testid='hw-vm-heap-mb' name='vm_heap_mb' value='" + heap + "' size='6'> "
            "Partition MB <input data-testid='hw-partition-size' name='partition_size' value='" + part + "' size='7'>"
            "</div>")

def csrf_field():
    if not CSRF_TOKEN:
        return ''
    return f"<input type='hidden' name='csrf' value='{html.escape(CSRF_TOKEN)}'>"

def page(body, msg=''):
    msg_html = f"<pre>{html.escape(msg)}</pre>" if msg else ''
    return render_ui_template('base.html', body=body, msg_html=msg_html)



def device_list_html():
    opts = device_options()
    rows = ''.join(f"<tr><td><code>{html.escape(d)}</code></td><td>{html.escape(label)}</td></tr>" for d, label in opts[:80])
    return "<div class='table-wrap compact-table'><table><tr><th>Device ID</th><th>Label</th></tr>" + rows + "</table></div>"

def api_list_html():
    cached = api_options()
    if not cached:
        return '<p class="small">No cached SDK list yet. Use Refresh SDK API/system-image list.</p>'
    lines = ''.join(f'<li>{html.escape(pkg)}</li>' for _, _, pkg in cached)
    return '<details><summary>Cached SDK system images</summary><ul>' + lines + '</ul></details>'


@app.get('/')
def index():
    host = PUBLIC_HOST or request.host.split(':')[0]
    api_cache_info = f"{len(api_options())} cached SDK system-image entries" if API_CACHE.exists() else "SDK API list not refreshed yet; built-in Android 13-16 presets are available"
    device_cache_info = f"{len(device_options())} device profiles available" + (" from SDK cache" if DEVICE_CACHE.exists() else " from built-in presets; refresh to read SDK device list")

    instances, warnings = rows()
    total = len(instances)
    headless_count = sum(1 for r in instances if r['mode'] == 'headless')
    novnc_count = sum(1 for r in instances if r['mode'] == 'novnc')
    apis_count = len(set(r['api'] for r in instances if r.get('api')))
    stats_html = (
        f"<div class='stats'>"
        f"<div class='stat'><b>{total}</b><span>instances</span></div>"
        f"<div class='stat'><b>{headless_count}</b><span>headless/scrcpy</span></div>"
        f"<div class='stat'><b>{novnc_count}</b><span>noVNC enabled</span></div>"
        f"<div class='stat'><b>{apis_count}</b><span>API levels in use</span></div>"
        f"</div>"
    )
    warn_html = ''.join(f"<div class='warn'>{html.escape(w)}</div>" for w in warnings)
    if warnings:
        warn_html += "<form method='post' action='/repair_records'>{csrf_field()}<button>Repair instance records</button></form>"

    table = '<tr><th>Name</th><th>Status</th><th>Mode</th><th>ADB</th><th>noVNC</th><th>API</th><th>Target</th><th>Device</th><th>HW</th></tr>'
    instance_cards = ''
    empty_notice = ""
    if not instances:
        empty_notice = "<div class='warn'>No instances in records. If an emulator is already running, use <b>Discover running pods</b>.</div>"
    for i, r in enumerate(instances):
        novnc = ''
        if r['mode'] == 'novnc' and r['novnc']:
            novnc_url_1x = f"http://{html.escape(host)}:{html.escape(r['novnc'])}/vnc.html?autoconnect=true&resize=off&path=websockify"
            novnc_url_scaled = f"http://{html.escape(host)}:{html.escape(r['novnc'])}/vnc.html?autoconnect=true&resize=scale&path=websockify"
            novnc_url_remote = f"http://{html.escape(host)}:{html.escape(r['novnc'])}/vnc.html?autoconnect=true&resize=remote&path=websockify"
            controlled_url = f"/novnc/{html.escape(r['name'])}"
            novnc = f"<a class='button-link' target='_blank' href='{controlled_url}'>Open with controls</a> <small>direct: <a target='_blank' href='{novnc_url_1x}'>1:1 {html.escape(r['novnc'])}</a> · <a target='_blank' href='{novnc_url_scaled}'>fit</a> · <a target='_blank' href='{novnc_url_remote}'>remote</a></small>"
        state = pod_state(r['name'])
        cmd = f"androidlab-scrcpy {host}:{r['adb']} --max-size 1280 --bit-rate 4M --stay-awake"
        cid = f'cmd_{i}'
        cmd_html = f"<textarea class='cmd' id='{cid}' readonly onclick='this.select()'>{html.escape(cmd)}</textarea><br><button type='button' onclick=\"return copyById('{cid}', this)\">Copy/select</button>"
        hw_summary = f"{html.escape(r.get('cpu','2'))}c / {html.escape(r.get('ram','4096'))}MB / heap {html.escape(r.get('heap','512'))} / part {html.escape(r.get('partition','4096'))}"
        hw_form = f"<form method='post' action='/apply_hw' class='actions hw-actions'>{csrf_field()}<input type='hidden' name='name' value='{html.escape(r['name'])}'>" + hw_inputs(r) + f"<button data-testid='apply-hw-{html.escape(r['name'])}'>Apply HW + restart</button></form>"
        disabled = " disabled" if state == 'missing' else ""
        power_form = f"<form method='post' action='/action' class='actions power-actions'>{csrf_field()}<input type='hidden' name='name' value='{html.escape(r['name'])}'><button data-testid='power-start-{html.escape(r['name'])}' name='op' value='start'{disabled}>Start</button><button data-testid='power-stop-{html.escape(r['name'])}' name='op' value='stop'{disabled}>Stop</button></form>"
        if r['mode'] == 'novnc':
            mode_button = "<button name='op' value='disable_novnc'>Disable noVNC</button>"
        else:
            mode_button = f"<select name='novnc_profile'>{novnc_profile_options()}</select><button name='op' value='enable_novnc'>Enable noVNC</button>"
        resize_form = ''
        if r['mode'] == 'novnc' and r['novnc']:
            resize_form = f"<form method='post' action='/resize_novnc' class='actions'>{csrf_field()}<input type='hidden' name='name' value='{html.escape(r['name'])}'><input type='hidden' name='novnc_port' value='{html.escape(r['novnc'])}'><select name='novnc_profile'>{novnc_profile_options()}</select><button>Apply size profile</button></form>"
        action_form = f"<form method='post' action='/action' class='actions compact-actions'>{csrf_field()}<input type='hidden' name='name' value='{html.escape(r['name'])}'>{mode_button}</form>{resize_form}"
        danger_form = f"<form method='post' action='/action' class='actions compact-actions'>{csrf_field()}<input type='hidden' name='name' value='{html.escape(r['name'])}'><button name='op' value='delete'>Delete</button><button name='op' value='wipe'>Wipe</button></form>"
        row_filter = html.escape(f"{r['name']} {state} {r['mode']} {r['adb']} {r['novnc']} api{r['api']} {r['target']} {r.get('device','pixel')} {r.get('cpu','2')}c {r.get('ram','4096')}mb")
        novnc_display = novnc or "<span class='small'>noVNC disabled</span>"
        instance_cards += (
            f"<div class='instance-card' data-testid='instance-card-{html.escape(r['name'])}' data-filter='{row_filter}'>"
            f"<div class='instance-head'><div><div class='instance-name'>{html.escape(r['name'])}</div>"
            f"<div class='instance-meta'><span>{html.escape(r['mode'])}</span><span>ADB {html.escape(r['adb'])}</span>"
            f"<span>API {html.escape(r['api'])}</span><span>{html.escape(r['target'])}</span>"
            f"<span>Device {html.escape(r.get('device','pixel'))}</span><span>HW {hw_summary}</span></div></div>{state_badge(state)}</div>"
            f"<div class='instance-layout'>"
            f"<div class='instance-block instance-access'><h4>Access</h4>{power_form}<div class='small' style='margin-top:.6rem'>scrcpy command</div>{cmd_html}<div style='margin-top:.5rem'>{novnc_display}</div></div>"
            f"<div class='instance-block'><h4>Runtime controls</h4>{action_form}{hw_form}</div>"
            f"<div class='instance-block danger-zone'><h4>Danger zone</h4>{danger_form}</div>"
            f"</div></div>"
        )
        table_novnc = html.escape(r['novnc']) if (r['mode'] == 'novnc' and r['novnc']) else ''
        table += f"<tr class='instance-row' data-filter='{row_filter}'><td title='{html.escape(r['name'])}'>{html.escape(r['name'])}</td><td>{state_badge(state)}</td><td>{html.escape(r['mode'])}</td><td>{html.escape(r['adb'])}</td><td>{table_novnc}</td><td>{html.escape(r['api'])}</td><td title='{html.escape(r['target'])}'>{html.escape(r['target'])}</td><td title='{html.escape(r.get('device','pixel'))}'>{html.escape(r.get('device','pixel'))}</td><td title='{hw_summary}'>{hw_summary}</td></tr>"

    body = f"""
{warn_html}
<div class='view' id='view-overview'>
{stats_html}
<div class='card full'><div class='section-title'><h2>Overview</h2><span class='pill'>verified UI</span></div>
<div class='feature-proof'><span>Phone model selector enabled</span><span>Start/Stop controls enabled</span><span>SDK profile refresh enabled</span><span>Hardware overrides enabled</span><span>Build-before-spawn enabled</span></div>
<p>Use the sidebar to switch between focused sections. Instances are managed from the Instances view; new emulators are created from Spawn; Android API/device profiles are in Profiles.</p>
</div>
</div>

<div class='view' id='view-spawn'>
<div class='section-grid'>
<div class='card' id='spawn'><div class='section-title'><h2>Spawn emulator instance</h2><span class='pill'>auto ports</span></div>
<form method='post' action='/spawn'>
{csrf_field()}
<div class='form-row'>Name <input name='name' value='android-emu13-extra'>
Mode <select name='mode'><option>headless</option><option>novnc</option></select></div>
<div class='form-row'>Android version/API <select name='preset'>{preset_options()}</select></div>
<div class='form-row'>Phone model <select id='spawn-device-profile' data-testid='spawn-device-profile' name='device_profile'>{device_profile_options()}</select> Custom <input data-testid='spawn-device-custom' name='device_custom' placeholder='e.g. pixel_6'></div>
<div class='form-row'>noVNC size profile <select name='novnc_profile'>{novnc_profile_options()}</select></div>
{hw_inputs()}
<label class='small'><input type='checkbox' name='build_first' value='1'> Build/update image before spawn (background progress)</label>
<div class='form-row'>Optional custom API <input name='api' placeholder='e.g. 36'>
Optional custom target <input name='target' placeholder='google_apis or google_apis_playstore'>
<button>Spawn with auto ports</button></div>
</form>
<p class='small'>Spawn auto-allocates ADB ports from 13555 upward and noVNC ports from 13080 upward. If build-before-spawn is checked, the manager starts a background job and shows live progress.</p></div>

<div class='card' id='manual'><div class='section-title'><h2>Manual create with fixed ports</h2><span class='pill'>advanced</span></div>
<form method='post' action='/create'>
{csrf_field()}
<div class='form-row'>Name <input name='name' value='android-emu13-manual'>
ADB <input name='adb' value='13556'>
Mode <select name='mode'><option>headless</option><option>novnc</option></select>
noVNC <input name='novnc' value='13080'></div>
<div class='form-row'>Android version/API <select name='preset'>{preset_options()}</select></div>
<div class='form-row'>Phone model <select id='manual-device-profile' data-testid='manual-device-profile' name='device_profile'>{device_profile_options()}</select> Custom <input data-testid='manual-device-custom' name='device_custom' placeholder='e.g. pixel_6'></div>
<div class='form-row'>noVNC size profile <select name='novnc_profile'>{novnc_profile_options()}</select></div>
{hw_inputs()}
<label class='small'><input type='checkbox' name='build_first' value='1'> Build/update image before create (background progress)</label>
<div class='form-row'>Optional custom API <input name='api' placeholder='e.g. 36'>
Optional custom target <input name='target' placeholder='google_apis or google_apis_playstore'>
<button>Create</button></div>
</form></div>
</div>
</div>

<div class='view' id='view-profiles'>
<div class='section-grid'>
<div class='card' id='api'><div class='section-title'><h2>Build/update API image</h2><span class='pill'>SDK images</span></div>
<form method='post' action='/build_api'>
{csrf_field()}
Android version/API <select name='preset'>{preset_options()}</select><br>
Optional custom API <input name='api' placeholder='e.g. 36'>
Optional custom target <input name='target' placeholder='google_apis or google_apis_playstore'>
<button>Build/update image</button>
</form>
<form method='post' action='/api_list'>{csrf_field()}<button>Refresh SDK API/system-image list</button></form>
<p class='small'>{html.escape(api_cache_info)}</p>
{api_list_html()}
</div>

<div class='card' id='profiles'><div class='section-title'><h2>Runtime profiles</h2><span class='pill'>device + display</span></div>
<p class='small'>Phone model/device profiles are used when a new AVD is first created. Existing AVD data keeps its original hardware profile.</p>
<form method='post' action='/device_list'>{csrf_field()}<button>Refresh SDK device-profile list</button></form>
<p class='small'>{html.escape(device_cache_info)}</p>
{device_list_html()}
</div>
</div>
</div>

<div class='view' id='view-instances'>
<div class='card full' id='instances'><div class='section-title'><h2>Instances</h2><span class='pill'>live records</span></div>
<p>Instance cards contain controls and commands. The table is compact/read-only to prevent wrapped, malformed rows.</p>
<div class='toolbar'><input id='instanceSearch' oninput='filterInstances(this.value)' placeholder='Filter by name, mode, API, target, port...'></div>
{empty_notice}<div class='instance-cards'>{instance_cards}</div><div class='table-wrap'><table class='readable-table'>{table}</table></div>
<form method='post' action='/clean'>{csrf_field()}<button name='wipe' value='0'>Clean all</button><button name='wipe' value='1'>Clean all + wipe</button></form>
<form method='post' action='/repair_records'>{csrf_field()}<button>Repair instance records</button></form><form method='post' action='/discover_running'>{csrf_field()}<button>Discover running pods</button></form></div>
</div>

<div class='view' id='view-frida'>
<div class='card full' id='frida'><div class='section-title'><h2>Frida upload</h2><span class='pill'>instrumentation</span></div>
<form method='post' action='/frida' enctype='multipart/form-data'>
{csrf_field()}
Instance <select name='name'>{''.join(f"<option>{html.escape(r['name'])}</option>" for r in instances)}</select>
File <input type='file' name='file'>
<label><input type='checkbox' name='start' value='1'> start</label>
<button>Upload</button>
</form></div>
</div>
"""
    return page(body)


@app.post('/spawn')
def spawn():
    name = request.form.get('name', '').strip()
    mode = request.form.get('mode', 'headless')
    api, target = parse_api_target(request.form)
    if not NAME_RE.match(name):
        return page(back('spawn', 'Back to Spawn'), 'Invalid name')
    device = parse_device_profile(request.form)
    hw = parse_hw_profile(request.form)
    env = merge_env(novnc_env_from_form(request.form), hw)
    if not valid_mode(mode) or not valid_api_target(api, target) or not valid_device_profile(device) or not valid_hw_profile(hw):
        return page(back('spawn', 'Back to Spawn'), 'Invalid mode/API/target/device/HW')
    if request.form.get('build_first') == '1':
        steps = [
            {'args': ['build-api', api, target, 'x86_64'], 'env': {}},
            {'args': ['spawn', name, mode, api, target, device], 'env': env},
        ]
        job_id = start_background_job(f'Build API {api}/{target} and spawn {name}', steps)
        return job_page(job_id, f'Building image and spawning {html.escape(name)}')
    if not image_exists(api, target, mode):
        missing = image_name(api, target, mode)
        return page(back('spawn', 'Back to Spawn'), f"Image missing: {missing}\nUse Profiles → Build/update image or enable 'Build/update image before spawn'.")
    return page(back('spawn', 'Back to Spawn'), run(['spawn', name, mode, api, target, device], env))


@app.post('/create')
def create():
    name = request.form.get('name', '').strip()
    adb = request.form.get('adb', '').strip()
    mode = request.form.get('mode', 'headless')
    novnc = request.form.get('novnc', '').strip()
    api, target = parse_api_target(request.form)
    if not NAME_RE.match(name):
        return page(back('spawn', 'Back to Spawn'), 'Invalid name')
    device = parse_device_profile(request.form)
    hw = parse_hw_profile(request.form)
    env = merge_env(novnc_env_from_form(request.form), hw)
    if not valid_mode(mode) or not valid_api_target(api, target) or not valid_device_profile(device) or not valid_hw_profile(hw):
        return page(back('spawn', 'Back to Spawn'), 'Invalid mode/API/target/device/HW')
    args = ['create', name, adb, mode, api, target]
    if mode == 'novnc':
        args.append(novnc)
        args.append(device)
    else:
        args.append(device)
    if request.form.get('build_first') == '1':
        steps = [
            {'args': ['build-api', api, target, 'x86_64'], 'env': {}},
            {'args': args, 'env': env},
        ]
        job_id = start_background_job(f'Build API {api}/{target} and create {name}', steps)
        return job_page(job_id, f'Building image and creating {html.escape(name)}')
    if not image_exists(api, target, mode):
        missing = image_name(api, target, mode)
        return page(back('spawn', 'Back to Spawn'), f"Image missing: {missing}\nUse Profiles → Build/update image or enable 'Build/update image before create'.")
    return page(back('spawn', 'Back to Spawn'), run(args, env))


@app.post('/build_api')
def build_api():
    api, target = parse_api_target(request.form)
    if not valid_api_target(api, target):
        return page('', 'Invalid API/target')
    job_id = start_background_job(f'Build API {api}/{target}', [{'args': ['build-api', api, target, 'x86_64'], 'env': {}}])
    return job_page(job_id, f'Building API image {html.escape(api)} / {html.escape(target)}')


@app.post('/api_list')
def api_list():
    return page(back('profiles', 'Back to Profiles'), run(['api-list']))


@app.post('/device_list')
def device_list_route():
    return page(back('profiles', 'Back to Profiles'), run(['device-list']))


@app.post('/repair_records')
def repair_records():
    return page(back('instances', 'Back to Instances'), run(['repair-records']))


@app.post('/discover_running')
def discover_running():
    return page(back('instances', 'Back to Instances'), run(['discover-running']))


@app.post('/action')
def action():
    name = request.form.get('name', '')
    op = request.form.get('op', '')
    if not NAME_RE.match(name):
        return page('', 'Invalid name')
    if op == 'wipe':
        args = ['delete', name, '--wipe']
        return page(back('instances', 'Back to Instances'), run(args))
    elif op == 'stop':
        args = ['stop', name]
        return page(back('instances', 'Back to Instances'), run(args))
    elif op == 'start':
        args = ['start', name]
        return page(back('instances', 'Back to Instances'), run(args))
    elif op == 'enable_novnc':
        args = ['enable-novnc', name]
        return page(back('instances', 'Back to Instances'), run(args, novnc_env_from_form(request.form)))
    elif op == 'disable_novnc':
        args = ['disable-novnc', name]
        return page(back('instances', 'Back to Instances'), run(args))
    elif op == 'delete':
        args = ['delete', name]
        return page(back('instances', 'Back to Instances'), run(args))
    return page('', 'Invalid action')



@app.post('/resize_novnc')
def resize_novnc():
    name = request.form.get('name', '').strip()
    novnc_port = request.form.get('novnc_port', '').strip()
    if not NAME_RE.match(name):
        return page('', 'Invalid name')
    if not re.match(r'^[0-9]{4,5}$', novnc_port):
        return page('', 'Invalid noVNC port')
    msg, code = run_result(['disable-novnc', name])
    if code != 0:
        return page(back('instances', 'Back to Instances'), msg)
    msg2, _ = run_result(['enable-novnc', name, novnc_port], novnc_env_from_form(request.form))
    return page(back('instances', 'Back to Instances'), msg + '\n' + msg2)


@app.post('/apply_hw')
def apply_hw():
    name = request.form.get('name', '').strip()
    if not NAME_RE.match(name):
        return page(back('instances', 'Back to Instances'), 'Invalid name')
    hw = parse_hw_profile(request.form)
    if not valid_hw_profile(hw):
        return page(back('instances', 'Back to Instances'), 'Invalid HW profile')
    return page(back('instances', 'Back to Instances'), run(['apply-hw', name], hw))


@app.post('/clean')
def clean():
    return page(back('instances', 'Back to Instances'), run(['clean-all', '--wipe'] if request.form.get('wipe') == '1' else ['clean-all']))


@app.post('/frida')
def frida():
    name = request.form.get('name', '')
    f = request.files.get('file')
    if request.content_length and request.content_length > 200 * 1024 * 1024:
        return page('', 'Upload too large')
    if not NAME_RE.match(name) or not f:
        return page('', 'Invalid frida upload')
    dest = UPLOADS / f'frida-server-{name}'
    f.save(dest)
    args = ['frida', name, str(dest)]
    if request.form.get('start') == '1':
        args.append('--start')
    return page(back('frida', 'Back to Frida'), run(args))



@app.get('/job_status/<job_id>')
def job_status(job_id):
    safe = re.sub(r'[^a-zA-Z0-9_.-]', '', job_id)
    status_path = JOBS / f'{safe}.status'
    log_path = JOBS / f'{safe}.log'
    status = status_path.read_text(errors='replace').strip() if status_path.exists() else 'missing'
    log = log_path.read_text(errors='replace') if log_path.exists() else 'No log found'
    if len(log) > 200000:
        log = log[-200000:]
    return {'status': status, 'log': log}


def record_by_name(name):
    if not RECORDS.exists():
        return None
    for i, line in enumerate(RECORDS.read_text().splitlines(), 1):
        r, _warn = parse_record(line, i)
        if r and r.get('name') == name:
            return r
    return None


@app.get('/novnc/<name>')
def novnc_session(name):
    if not NAME_RE.match(name or ''):
        return page('', 'Invalid instance name')
    r = record_by_name(name)
    if not r or r.get('mode') != 'novnc' or not r.get('novnc'):
        return page('', 'Instance is not noVNC-enabled')
    host = PUBLIC_HOST or request.host.split(':')[0]
    src = f"http://{html.escape(host)}:{html.escape(r['novnc'])}/vnc.html?autoconnect=true&resize=scale&path=websockify"
    return page(render_ui_template('novnc.html', name=name, src=src, csrf_token=CSRF_TOKEN or ''))



@app.post('/keyevent')
def keyevent():
    name = request.form.get('name', '').strip()
    key = request.form.get('key', '').strip()
    if not NAME_RE.match(name):
        return Response('Invalid name', 400)
    if key not in ('back', 'triangle', 'home', 'circle', 'recents', 'recent', 'overview', 'square', 'app_switch', 'menu', 'power', 'volup', 'volumeup', 'voldown', 'volumedown'):
        return Response('Invalid key', 400)
    text, code = run_result(['key', name, key])
    return Response(text, 200 if code == 0 else 500, mimetype='text/plain')


def doc_meta(path, text):
    name = path.name
    title = path.stem.replace('_', ' ').title()
    for line in text.splitlines():
        if line.startswith('# '):
            title = line[2:].strip()
            break
    lower = name.lower()
    if any(x in lower for x in ['install', 'one_script', 'web_manager', 'spawn', 'modes']):
        category = 'Getting started'
        priority = 10
    elif any(x in lower for x in ['adb', 'frida', 'scrcpy', 'novnc', 'api']):
        category = 'Operator cheat sheets'
        priority = 20
    elif any(x in lower for x in ['security', 'clean', 'wipe', 'troubleshooting']):
        category = 'Operations and safety'
        priority = 30
    elif any(x in lower for x in ['code_review', 'runtime', 'regression', 'source', 'fixes', 'stale']):
        category = 'Engineering notes'
        priority = 40
    else:
        category = 'Reference'
        priority = 50
    summary = ''
    for line in text.splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith('#') and not stripped.startswith('```'):
            summary = stripped.lstrip('- ').strip()
            break
    return dict(name=name, title=title, category=category, priority=priority, summary=summary[:180])


def render_markdown(md_text):
    lines = md_text.splitlines()
    out = []
    in_code = False
    code_lines = []
    code_lang = ''
    list_type = None
    table_buf = []

    def close_list():
        nonlocal list_type
        if list_type:
            out.append(f'</{list_type}>')
            list_type = None

    def inline(text):
        text = html.escape(text)
        text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
        text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
        text = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', text)
        def link_repl(m):
            label = m.group(1)
            href = m.group(2)
            safe_href = href if re.match(r'^(https?://|/|#)', href) else '#'
            return f"<a href='{html.escape(safe_href)}'>{label}</a>"
        text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link_repl, text)
        return text

    def flush_table():
        nonlocal table_buf
        if not table_buf:
            return
        rows = table_buf
        table_buf = []
        if len(rows) < 2:
            for r in rows:
                out.append('<p>' + inline(r) + '</p>')
            return
        header = [c.strip() for c in rows[0].strip('|').split('|')]
        body_rows = rows[2:] if re.match(r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$', rows[1]) else rows[1:]
        html_rows = ['<div class="md-table-wrap"><table class="md-table"><thead><tr>']
        html_rows += [f'<th>{inline(c)}</th>' for c in header]
        html_rows.append('</tr></thead><tbody>')
        for row in body_rows:
            cells = [c.strip() for c in row.strip('|').split('|')]
            html_rows.append('<tr>' + ''.join(f'<td>{inline(c)}</td>' for c in cells) + '</tr>')
        html_rows.append('</tbody></table></div>')
        out.append(''.join(html_rows))

    for line in lines:
        stripped = line.strip()
        if stripped.startswith('```'):
            if not in_code:
                flush_table(); close_list()
                in_code = True
                code_lang = stripped[3:].strip() or 'code'
                code_lines = []
            else:
                lang_label = html.escape(code_lang)
                out.append('<div class="code-block"><div class="code-title">' + lang_label + '</div><pre><code>' + html.escape('\n'.join(code_lines)) + '</code></pre></div>')
                in_code = False
            continue
        if in_code:
            code_lines.append(line)
            continue
        if '|' in line and stripped.startswith('|'):
            close_list()
            table_buf.append(line)
            continue
        else:
            flush_table()
        if not stripped:
            close_list()
            continue
        if stripped == '---':
            close_list(); out.append('<hr>'); continue
        if stripped.startswith('>'):
            close_list(); out.append('<blockquote>' + inline(stripped.lstrip('> ').strip()) + '</blockquote>'); continue
        if stripped.startswith('### '):
            close_list(); out.append('<h3>' + inline(stripped[4:]) + '</h3>'); continue
        if stripped.startswith('## '):
            close_list(); out.append('<h2>' + inline(stripped[3:]) + '</h2>'); continue
        if stripped.startswith('# '):
            close_list(); out.append('<h1>' + inline(stripped[2:]) + '</h1>'); continue
        if stripped.startswith('- '):
            if list_type != 'ul':
                close_list(); out.append('<ul>'); list_type = 'ul'
            out.append('<li>' + inline(stripped[2:]) + '</li>')
            continue
        if re.match(r'^\d+\.\s+', stripped):
            if list_type != 'ol':
                close_list(); out.append('<ol>'); list_type = 'ol'
            out.append('<li>' + inline(re.sub(r'^\d+\.\s+', '', stripped)) + '</li>')
            continue
        close_list()
        out.append('<p>' + inline(stripped) + '</p>')
    flush_table(); close_list()
    if in_code:
        out.append('<div class="code-block"><div class="code-title">' + html.escape(code_lang or 'code') + '</div><pre><code>' + html.escape('\n'.join(code_lines)) + '</code></pre></div>')
    return '<article class="doc-body">' + '\n'.join(out) + '</article>'


@app.get('/docs')
def docs():
    docs_dir = LAB_HOME / 'docs'
    metas = []
    for p in sorted(docs_dir.glob('*.md')):
        text = p.read_text(errors='replace')
        meta = doc_meta(p, text)
        metas.append(meta)
    metas.sort(key=lambda m: (m['priority'], m['title']))
    sections = []
    current = None
    for meta in metas:
        if meta['category'] != current:
            if current is not None:
                sections.append('</div>')
            current = meta['category']
            sections.append(f"<h2 class='doc-category'>{html.escape(current)}</h2><div class='docs-grid'>")
        filt = html.escape(f"{meta['title']} {meta['name']} {meta['category']} {meta['summary']}")
        sections.append(
            f"<div class='doc-card' data-filter='{filt}'>"
            f"<span class='doc-chip'>{html.escape(meta['category'])}</span>"
            f"<h3><a href='/docs/{html.escape(meta['name'])}'>{html.escape(meta['title'])}</a></h3>"
            f"<p>{html.escape(meta['summary'])}</p>"
            f"<div class='doc-meta'>{html.escape(meta['name'])}</div>"
            f"</div>"
        )
    if current is not None:
        sections.append('</div>')
    body = (
        "<div class='card full'>"
        "<div class='section-title'><h2>Documentation</h2><span class='pill'>guides and cheat sheets</span></div>"
        "<p class='small'>Search docs by feature, command, topic, or filename.</p>"
        "<div class='docs-toolbar'><input oninput='filterDocs(this.value)' placeholder='Filter docs: adb, frida, novnc, api, security...'></div>"
        + ''.join(sections) +
        "</div>"
    )
    return page(body)


@app.get('/docs/<name>')
def doc_file(name):
    safe = re.sub(r'[^a-zA-Z0-9_.-]', '', name)
    p = LAB_HOME / 'docs' / safe
    if not p.exists():
        return page('', 'Doc not found')
    body = "<p><a href='/docs'>← Back to docs</a></p>" + render_markdown(p.read_text(errors='replace'))
    return page(body)


if __name__ == '__main__':
    app.run(host=HOST, port=PORT)
