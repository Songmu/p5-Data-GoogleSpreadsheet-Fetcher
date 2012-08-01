use inc::Module::Install;
name 'Data-GoogleSpreadSheet-Manager';
all_from 'lib/Data/GoogleSpreadSheet/Manager.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
