use strict;
use warnings;

use Test::More;

use JSON::Schema::Validator;

use_ok 'JSON::Schema::Validator::Attributes::Ref';

subtest 'validation with $ref referencing' => sub {
    my ($res, $err);
    my $v = JSON::Schema::Validator->new({
        type => 'object',
        definitions => {
            person => {
                type => 'object',
                properties => {
                    first => { type => 'string' },
                    last  => { type => 'string' },
                },
                required => [qw(first last)],
            },
        },
        properties => {
            name => { '$ref' => '#/definitions/person' },
            age  => { type => 'integer' },
        },
    });
    ($res, $err) = $v->validate({
        name => { first => 'foo', last => 'bar' },
        age  => 12
    });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({
        name => { first => 'foo' },
        age  => 10,
    });
    ok !$res;
    is $err->position, '/properties/name/$ref/required';
};

subtest 'validate with nested $ref referencing' => sub {
    my ($res, $err);
    my $v = JSON::Schema::Validator->new({
        type => 'object',
        definitions => {
            person => {
                type => 'object',
                properties => {
                    first    => { type => 'string' },
                    last     => { type => 'string' },
                    address  => { '$ref' => '#/definitions/person/definitions/address' },
                },
                required => [qw(first last address)],
                definitions => {
                    address => {
                        type   => 'object',
                        properties => {
                            code   => { type => 'integer'},
                            street => { type => 'string'},
                        }
                    },
                },
            },
        },
        properties => {
            person => { '$ref' => '#/definitions/person' },
        },
    });

    ($res, $err) = $v->validate({
        person => {
            first   => 'ababa',
            last    => 'abebe',
            address => { code => 123, street => 'unadon' },
        },
    });
    ok $res;
    is $err, undef;

    ($res, $err) = $v->validate({
        person => {
            first   => 'a',
            last    => 'a',
            address => { code => 345.1, street => 'hamachi' },
        },
    });
    ok !$res;
    is $err->position, '/properties/person/$ref/properties/address/$ref/properties/code/type';

    ($res, $err) = $v->validate({
        person => {
            first   => 'a',
            last    => [],
            address => { code => 4, street => 'kegani' },
        },
    });
    ok !$res;
    is $err->position, '/properties/person/$ref/properties/last/type';

    ($res, $err) = $v->validate({
        person => {
            first   => 'a',
            address => { code => 4, street => 'kegani' },
        },
    });
    ok !$res;
    is $err->position, '/properties/person/$ref/required';

};

done_testing;
