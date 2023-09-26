function [keys] = ImportKeys(t)

if strcmp(t.hostname,'stimpc1') % curdes button box single diamond (HID NAR 12345)
    %KbName('UnifyKeyNames');
    keys.keyList                  = KbName('KeyNames');
    keys.name.painful             = KbName('4$');
    keys.name.notPainful          = KbName('2@');
    keys.name.abort               = KbName('esc');
    keys.name.pause               = KbName('space');
    keys.name.resume              = KbName('return');
    keys.name.left                = KbName('2@'); % yellow button
    keys.name.right               = KbName('4$'); % red button
    keys.name.confirm             = KbName('3#'); % green button
    keys.name.esc                 = KbName('esc');
    %keys.esc                 = KbName('Escape');
else
    KbName('UnifyKeyNames');
    keys.keyList                  = KbName('KeyNames');
    keys.name.painful             = KbName('RightArrow');
    keys.name.notPainful          = KbName('LeftArrow');
    keys.name.abort               = KbName('Escape');
    keys.name.pause               = KbName('Space');
    keys.name.resume              = KbName('Return');
    keys.name.confirm             = KbName('Return');
    keys.name.right               = KbName('RightArrow');
    keys.name.left                = KbName('LeftArrow');
    keys.name.down                = KbName('DownArrow');
    keys.name.esc                 = KbName('Escape');
end