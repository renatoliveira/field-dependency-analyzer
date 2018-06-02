/*
Copyright 2018 Renato Oliveira

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
@IsTest
private class FieldDependencyTest {
    @IsTest
    static void test_instance() {
        String recordAsJson = '{' +
            '"ConditionOperator__c": "IS_NOT_EMPTY",' +
            '"RuleOperator__c": "IS_NOT_EMPTY",' +
            '"ConditionField__c": "Origin",' +
            '"RuleField__c": "Reason",' +
            '"ObjectAPIName__c": "Case"' +
            '}';

        FieldRule__mdt fdmdt = (FieldRule__mdt) JSON.deserialize(recordAsJson, FieldRule__mdt.class);
        FieldDependency fd = new FieldDependency(
            'Origin',
            'IS_NOT_EMPTY',
            null,
            'Reason',
            'IS_NOT_EMPTY',
            null,
            'Case',
            null,
            '',
            ''
        );
        fd = new FieldDependency(fdmdt);
    }
}