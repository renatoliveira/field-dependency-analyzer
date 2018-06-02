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
private class FieldDependencyAnalyzerTest {
    @IsTest
    static void test_analysis_picklists_1 () {
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer(new List<String>{'Case'});
        analyzer.rulesByObject = new Map<String, List<FieldDependency>>();
        analyzer.rulesByObject.put('case', new List<FieldDependency>());
        String errorMessage = 'If origin is specified, then the reason should be too.';
        analyzer.rulesByObject.get('case').add(new FieldDependency(
            'Origin',
            'IS_NOT_EMPTY',
            null,
            'Reason',
            'IS_NOT_EMPTY',
            null,
            'Case',
            null,
            errorMessage,
            'API_NAME'
        ));

        Case record = new Case(
            Origin = 'Email'
        );

        List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult> results = analyzer.analyze(
            new List<SObject>{record},
            'Case',
            null
        );

        Map<String, SObjectField> fields = Schema.getGlobalDescribe().get('Case').getDescribe().fields.getMap();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess());
        System.assertEquals(errorMessage, results[0].getMessage());
        System.assertEquals(fields.get('Reason').getDescribe().getLabel(), results[0].getField());
    }

    @IsTest
    static void test_analysis_picklists_2 () {
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer(new List<String>{'Case'});
        analyzer.rulesByObject = new Map<String, List<FieldDependency>>();
        analyzer.rulesByObject.put('case', new List<FieldDependency>());
        String errorMessage = 'If origin is specified, then the reason should be too.';
        analyzer.rulesByObject.get('case').add(new FieldDependency(
            'Origin',
            'IS_NOT_EMPTY',
            null,
            'Reason',
            'IS_NOT_EMPTY',
            null,
            'Case',
            null,
            errorMessage,
            'API_NAME'
        ));

        Case record = new Case(
            Origin = 'Email',
            Reason = 'Something'
        );

        List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult> results = analyzer.analyze(
            new List<SObject>{record},
            'Case',
            null
        );

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess());
        System.assertEquals('', results[0].getMessage());
    }

    @IsTest
    static void test_analysis_picklists_3 () {
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer(new List<String>{'Case'});
        analyzer.rulesByObject = new Map<String, List<FieldDependency>>();
        analyzer.rulesByObject.put('case', new List<FieldDependency>());
        String errorMessage = 'If origin is "Email", then the reason should be informed.';
        analyzer.rulesByObject.get('case').add(new FieldDependency(
            'Origin',
            'EQUALS',
            'Email',
            'Reason',
            'IS_NOT_EMPTY',
            null,
            'Case',
            null,
            errorMessage,
            'API_NAME'
        ));

        Case record = new Case(
            Origin = 'Email'
        );

        List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult> results = analyzer.analyze(
            new List<SObject>{record},
            'Case',
            null
        );

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess());
        System.assertEquals(errorMessage, results[0].getMessage());
    }

    @IsTest
    static void test_analysis_picklists_4 () {
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer(new List<String>{'Case'});
        analyzer.rulesByObject = new Map<String, List<FieldDependency>>();
        analyzer.rulesByObject.put('case', new List<FieldDependency>());
        String errorMessage = 'If origin is "Email", then the reason should be informed.';
        analyzer.rulesByObject.get('case').add(new FieldDependency(
            'Origin',
            'EQUALS',
            'Email',
            'Reason',
            'IS_NOT_EMPTY',
            null,
            'Case',
            null,
            errorMessage,
            'API_NAME'
        ));

        Case record = new Case(
            Origin = 'Email',
            Reason = 'Something'
        );

        List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult> results = analyzer.analyze(
            new List<SObject>{record},
            'Case',
            null
        );

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess());
        System.assertEquals('', results[0].getMessage());
    }

    @IsTest
    static void test_analysis_validate_change () {
        String ruleRecordJSON = '{"ConditionOperator__c": "IS_NOT_EMPTY", "RuleOperator__c": "IS_CHANGED", ' +
            '"ConditionField__c": "Origin", "RuleField__c": "Origin", "Object__c": "Case"}';
        FieldRule__mdt ruleMetadata =
            (FieldRule__mdt) JSON.deserialize(ruleRecordJSON, FieldRule__mdt.class);
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer('Case');
        Id caseId = IDGenerator.generate(Case.SObjectType);
        Case currentRecordVersion = new Case(
            Id = caseId,
            Origin = 'Email'
        );
        Case previousRecordVersion = new Case(
            Id = caseId,
            Origin = 'Email'
        );
        FieldDependency rule = new FieldDependency(ruleMetadata);
        Boolean result = analyzer.validateChange(
            rule.ruleField,
            rule.ruleOperator,
            currentRecordVersion,
            previousRecordVersion
        );
        System.assertEquals(true, result, 'Should be a valid record since there are no changes to "Origin".');

        previousRecordVersion.Origin = 'Phone';
        result = analyzer.validateChange(
            rule.ruleField,
            rule.ruleOperator,
            currentRecordVersion,
            previousRecordVersion
        );

        System.assertEquals(false, result, 'Should be an invalid record since "Origin" was modified.');
    }

    @IsTest
    static void test_second_field_handling () {
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer('Case');
        Case record = new Case(
            Origin = 'Email',
            Subject = ''
        );
        Case previousVersion = new Case(
            Origin = 'Phone'
        );
        Boolean result = null;

        result = analyzer.handleSecondFieldAnalysis(
            'EQUALS', 'Origin', 'Phone', record, null
        );
        System.assertEquals(
            false, result,
            'Should detect that the rule specifies Origin should be "Phone" instead of "Email".'
        );

        result = analyzer.handleSecondFieldAnalysis(
            'NOT_EQUALS', 'Origin', 'Email', record, null
        );
        System.assertEquals(
            false, result,
            'Should detect that the rule specifies Origin should not be "Email".'
        );

        result = analyzer.handleSecondFieldAnalysis(
            'IS_NOT_EMPTY', 'Subject', null, record, null
        );
        System.assertEquals(
            false, result,
            'Should detect that the rule specifies the Subject should not be empty'
        );

        result = analyzer.handleSecondFieldAnalysis(
            'IS_EMPTY', 'Origin', null, record, null
        );
        System.assertEquals(
            false, result,
            'Should detect that the rule specifies the Origin should be empty.'
        );

        result = analyzer.handleSecondFieldAnalysis(
            'IS_CHANGED', 'Origin', null, record, previousVersion
        );
        System.assertEquals(
            false, result,
            'Should detect that the Origin should not change.'
        );
    }

    @IsTest
    static void test_record_type_detection () {
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer('Case');
        Id recordTypeId = IDGenerator.generate(new RecordType().getSObjectType());
        Boolean result = null;

        result = analyzer.analyzeByRecordType('RecordTypeName', recordTypeId, new Map<Id, String>{
            recordTypeId => 'RecordTypeName'
        });
        System.assertEquals(result, true);

        result = analyzer.analyzeByRecordType('RecordTypeName', recordTypeId, new Map<Id, String>{
            recordTypeId => 'AnotherRecordTypeName'
        });
        System.assertEquals(result, false);

        result = analyzer.analyzeByRecordType(null, recordTypeId, null);
        System.assertEquals(result, true);
    }

    @IsTest
    static void test_init () {
        String recordAsJson = '{"ConditionOperator__c": "IS_NOT_EMPTY", "RuleOperator__c": "IS_NOT_EMPTY", ' +
            '"ConditionField__c": "Reason", "RuleField__c": "Origin", "Object__c": "Case"}';
        FieldRule__mdt fdmdt = (FieldRule__mdt) JSON.deserialize(recordAsJson, FieldRule__mdt.class);
        FieldDependencyAnalyzer analyzer = new FieldDependencyAnalyzer('Case');
        analyzer.init(new List<FieldRule__mdt>{fdmdt});
    }
}