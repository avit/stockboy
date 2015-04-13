# Changelog

## 0.11.0 / 2015-04-13

* [FEATURE]     Options to set POST body and headers
 
## 0.10.0 / 2015-01-23

* [FEATURE]     Option to ignore unwanted attributes from output
 
## 0.9.0 / 2014-05-19

* [FEATURE]     Add JSON reader 
 
## 0.8.1 / 2014-04-24

* [BUGFIX]      Support `data_size` for non-string providers
* [BUGFIX]      Checks for nil data and nil configuration options

## 0.8.0 / 2014-04-02

* [ENHANCEMENT] Expose `data_time` and `data_size` in repeater
* [ENHANCEMENT] Expose `data?` method to check for loaded data

## 0.7.2 / 2014-04-02

* [BUGFIX]      Require missing repeater class in DSL

## 0.7.1 / 2014-03-25

* [ENHANCEMENT] Job initializes with an empty attribute map to allow adding
* [ENHANCEMENT] Default to rails logger when loaded
* [ENHANCEMENT] Use same configured logger for all provider clients
* [BUGFIX]      Compatibility with Rubinius

## 0.7.0 / 2014-03-21

* [FEATURE]     Add individual attribute mappings
* [FEATURE]     Repeat provider requests to fetch paginated data
* [ENHANCEMENT] More configurable SOAP options (@markedmondson)
* Removed ActiveModel errors, configuration errors are simple arrays now

## 0.6.0 / 2014-02-06

* [FEATURE]     Support HTTP basic authentication (@markedmondson)
* [ENHANCEMENT] Accept any duck-typed hash-like input when building a record

## 0.5.7 / 2013-12-13

* [BUGFIX]      Fix IMAP search with missing search defaults

## 0.5.6 / 2013-12-12

* [BUGFIX]      Fix requiring of nested module

## 0.5.5 / 2013-12-12

* [BUGFIX]      Ensure IMAP connections are reused and closed
* [ENHANCEMENT] Expose IMAP search options for reuse

## 0.5.4 / 2013-12-04

* [BUGFIX]      Fixed broken IMAP client

## 0.5.3 / 2013-12-04

* [BUGFIX]      Fix broken encoding option in fixed-width reader
* [BUGFIX]      Fix missing IMAP attachment validation DSL options

## 0.5.2 / 2013-12-04

* [BUGFIX]      Registered :string translation that was missed
* [BUGFIX]      All date translators handle String / Date / Time correctly

## 0.5.1 / 2013-12-03

* [ENHANCEMENT] Link to full documentation and license
* [ENHANCEMENT] Add CI test environment and code metrics

## 0.5.0 / 2013-12-03

* [FEATURE]     YARD documentation throughout
* [FEATURE]     Triggers for invoking actions in job context
* [FEATURE]     Add generic `delete_data` method for cleanup of matched files
* [ENHANCEMENT] Expose provider `client` for reuse
* [ENHANCEMENT] Expose provider `matching_file` for reuse
* [BUGFIX]      Add missing file validations

## 0.4.3 / 2013-11-22

* [ENHANCEMENT] Optimize CSV memory usage with shared hash keys
* [BUGFIX]      Missed a required file for SOAP/XML

## 0.4.2 / 2013-11-21

* [ENHANCEMENT] Use consistent conversion for XML hash keys

## 0.4.1 / 2013-11-19

First post!

