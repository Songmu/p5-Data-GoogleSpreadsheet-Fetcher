use inc::Module::Install;
name 'Data-GoogleSpreadsheet-Fetcher';
all_from 'lib/Data/GoogleSpreadsheet/Fetcher.pm';

requires 'Any::Moose';
requires 'Net::Google::Spreadsheets';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
