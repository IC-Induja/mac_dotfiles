import os

OPAQUE = 1.0
TRANSLUCENT = 0.8

def main(args):
    return ''

def handle_result(args, answer, target_window_id, boss):
    from kitty.fast_data_types import change_background_opacity
    wid = boss.active_tab.os_window_id
    tfile = f'/tmp/kitty-opacity-{wid}'
    if os.path.exists(tfile):
        os.remove(tfile)
        change_background_opacity(wid, OPAQUE)
    else:
        open(tfile, 'w').close()
        change_background_opacity(wid, TRANSLUCENT)
