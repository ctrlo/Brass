#!perl

use strict;
use warnings;

use Test::More;
use List::Util 'any';

use Brass::Actions;

ok any { $_ eq 'system' } Brass::Actions::allowed_actions(),
    'The "system" action exists';
ok Brass::Actions::is_allowed_action('system'),
    'The "system" action is allowed';
ok !Brass::Actions::is_allowed_action('this action should not exist'),
    'A non-existent action is not allowed';
ok Brass::Actions::action_requires_pwd('system'),
    'The "system" action requires a password';
ok Brass::Actions::is_allowed_action('admonitor'),
    'The "admonitor" action is allowed';
ok !Brass::Actions::action_requires_pwd('admonitor'),
    'The "admonitor" action does not require a password';

done_testing();
