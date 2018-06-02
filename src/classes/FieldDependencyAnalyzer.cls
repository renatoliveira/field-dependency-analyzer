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
public without sharing class FieldDependencyAnalyzer {
    public Map<String, List<FieldDependency>> rulesByObject;

    public FieldDependencyAnalyzer(String sObjectName) {
        this(new List<String>{sObjectName});
    }

    public FieldDependencyAnalyzer(List<String> objectNames) {
        init([
            SELECT
                Id
                ,ConditionField__c
                ,ConditionOperator__c
                ,ConditionValue__c
                ,RuleField__c
                ,RuleOperator__c
                ,RuleValue__c
                ,Object__c
                ,ErrorMessage__c
                ,RecordType__c
                ,DeveloperName
            FROM FieldRule__mdt
            WHERE Active__c = TRUE
            AND Object__c IN :objectNames
        ]);
    }

    /**
     * Initialize the analysis class with searched rules.
     *
     * @param rules
     */
    @TestVisible
    private void init (List<FieldRule__mdt> rules) {
        rulesByObject = new Map<String, List<FieldDependency>>();
        for (FieldRule__mdt fd : rules) {
            String objectName = fd.Object__c.toLowerCase();
            if (!rulesByObject.containsKey(objectName)) {
                rulesByObject.put(objectName, new List<FieldDependency>());
            }
            rulesByObject.get(objectName).add(new FieldDependency(fd));
        }
    }

    /**
     * Gets the records to analyze and analyze them.
     *
     * @param records SObjects to analyze
     * @param sObjectName API name of the object list type being analyzed ('Account' or 'Opportunity', for example).
     * @param previousObjectVersion Map of old records (trigger.old)
     *
     * @return list of analysis results
     */
    public List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult> analyze (List<SObject> records,
        String sObjectName, Map<Id, SObject> previousObjectVersion) {
        List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult> analysisResult
            = new List<FieldDependencyAnalyzer.FieldDependencyAnalysisResult>();
        Map<Id, String> recordTypes = getRecordTypes(sObjectName);
        Boolean hasRecordTypes = hasRecordTypes(sObjectName);
        for (SObject record : records) {
            for (FieldDependency rule : rulesByObject.get(sObjectName.toLowerCase())) {
                Boolean recordIsValid = true;
                Boolean recordTypeMatch = true;
                if (hasRecordTypes) {
                    recordTypeMatch = analyzeByRecordType(record, rule.recordType, recordTypes);
                }
                SObject previousVersion = getPreviousVersion(record, previousObjectVersion);
                if (!recordTypeMatch) {
                    continue;
                }
                if (rule.conditionOperator == 'IS_NOT_EMPTY' &&
                    String.isNotBlank(String.valueOf(record.get(String.valueOf(rule.conditionField))))) {
                    recordIsValid = handleSecondFieldAnalysis(rule, record, previousVersion);
                } else if (rule.conditionOperator == 'IS_EMPTY' &&
                    String.isBlank(String.valueOf(record.get(String.valueOf(rule.conditionField))))) {
                    recordIsValid = handleSecondFieldAnalysis(rule, record, previousVersion);
                } else if (rule.conditionOperator == 'EQUALS' &&
                    String.valueOf(record.get(rule.conditionField)) == rule.conditionValue) {
                    recordIsValid = handleSecondFieldAnalysis(rule, record, previousVersion);
                } else if (rule.conditionOperator == 'NOT_EQUALS' &&
                    String.valueOf(record.get(rule.conditionField)) != rule.conditionValue) {
                    recordIsValid = handleSecondFieldAnalysis(rule, record, previousVersion);
                }
                if (recordIsValid) {
                    analysisResult.add(new FieldDependencyAnalyzer.FieldDependencyAnalysisResult('', '', true));
                } else {
                    analysisResult.add(getErrorResult(rule, sObjectName));
                    if (Trigger.isExecuting) {
                        record.addError(rule.errorMessage);
                    }
                }
            }
        }
        return analysisResult;
    }

    /**
     * If run in a trigger update context, this returns the previous version of the record.
     *
     * @param record
     * @param oldMap
     *
     * @return previous version of said record. Null if in an insert context.
     */
    @TestVisible
    private SObject getPreviousVersion (SObject record, Map<Id, SObject> oldMap) {
        if (record.Id != null && oldMap != null) {
            return oldMap.get(record.Id);
        }
        return null;
    }

    /**
     * Validates a record change. If the rule specifies that the value should not be changed, for example.
     *
     * @param rule field dependency rule
     * @param record record to analyse
     * @param previousRecord previous version
     *
     * @return validation result (true if it is valid, false otherwise)
     */
    @TestVisible
    private Boolean validateChange (String dependentField, String dependentCondition, SObject record,
        SObject previousRecord) {
        String currentValue = String.valueOf(record.get(dependentField));
        String previousValue = String.valueOf(previousRecord.get(dependentField));
        if (currentValue != previousValue && dependentCondition == 'IS_CHANGED') {
            return false;
        } else if (currentValue == previousValue && dependentCondition == 'IS_NOT_CHANGED') {
            return false;
        }
        return true;
    }

    /**
     * Builds the analysis result object.
     *
     * @param rule
     * @param sObjectName
     *
     * @return analysis result object
     */
    @TestVisible
    private FieldDependencyAnalyzer.FieldDependencyAnalysisResult getErrorResult(FieldDependency rule,
        String sObjectName) {
        return new FieldDependencyAnalyzer.FieldDependencyAnalysisResult(
            getFieldName(sObjectName, rule.ruleField),
            rule.errorMessage,
            false
        );
    }

    /**
     * After handling the first argument, if the rule is a match, then we analyze the second rule here.
     *
     * @param rule
     * @param record
     *
     * @return if the rule matches (the record is invalid) or not.
     */
    private Boolean handleSecondFieldAnalysis (FieldDependency rule, SObject record, SObject previousVersion) {
        System.debug('Handling ' + rule.developerName + '...');
        return handleSecondFieldAnalysis(
            rule.ruleOperator,
            rule.ruleField,
            rule.ruleValue,
            record,
            previousVersion
        );
    }

    @TestVisible
    private Boolean handleSecondFieldAnalysis (String dependentCondition, String dependentField,
        String dependantTargetText, SObject record, SObject previousVersion) {
        if (dependentCondition == 'EQUALS' &&
            String.valueOf(record.get(dependentField)) != dependantTargetText) {
            return false;
        } else if (dependentCondition == 'NOT_EQUALS' &&
            String.valueOf(record.get(dependentField)) == dependantTargetText) {
            return false;
        } else if (dependentCondition == 'IS_NOT_EMPTY' &&
            String.isBlank(String.valueOf(record.get(dependentField)))) {
            return false;
        } else if (dependentCondition == 'IS_EMPTY' &&
            String.isNotBlank(String.valueOf(record.get(dependentField)))) {
            return false;
        } else if (dependentCondition == 'IS_CHANGED' &&
            previousVersion != null &&
            !validateChange(dependentField, dependentCondition, record, previousVersion)) {
            return false;
        }
        return true;
    }

    /**
     * Checks if the record should have this rule processed (that is: if the rule is for a specific record type and the
     * record has that type). If the rule doesn't specify a record type, then it is treated as a general rule and it
     * will be checked.
     *
     * @param record
     * @param rule
     * @param recordTypes
     *
     * @return boolean that indicates if the record should have the rule processed
     */
    private Boolean analyzeByRecordType (SObject record, String recordTypeName,
        Map<Id, String> recordTypes) {
        return analyzeByRecordType(
            recordTypeName,
            record.get('RecordTypeId') != null ? Id.valueOf(String.valueOf(record.get('RecordTypeId'))) : null,
            recordTypes
        );
    }

    @TestVisible
    private Boolean analyzeByRecordType (String recordTypeName, Id recordTypeId, Map<Id, String> recordTypeNames) {
        if (recordTypeName == null) {
            return true;
        } else if (recordTypeName != null &&
            recordTypeNames.containsKey(recordTypeId) != null &&
            recordTypeNames.get(recordTypeId) == recordTypeName) {
            return true;
        }
        return false;
    }

    /**
     * Checks if the given object has record types or not. If it doesn't, then we don't need to check for its record
     * type-specific rules, because they shouldn't exist.
     *
     * @param sObjectAPIName API name of the object we want to know if has record types
     *
     * @return true if it has record types, false otherwise.
     */
    private Boolean hasRecordTypes (String sObjectAPIName) {
        Map<String, Schema.SObjectType> mapGlobalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objSObjectType = mapGlobalDescribe.get(sObjectAPIName);
        Map<String, Schema.SObjectField> mapFieldDescribe =
            objSObjectType.getDescribe().fields.getMap();
        return mapFieldDescribe.containsKey('RecordTypeId');
    }

    /**
     * Get the object's record types.
     *
     * @param sObjectName object's API name
     *
     * @return map of recordtype infos by Id
     */
    private Map<Id, String> getRecordTypes (String sObjectName) {
        Map<Id, String> result = new Map<Id, String>();
        Map<Id, Schema.RecordTypeInfo> recordTypes =
            Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosById();
        for (Id recordTypeId : recordTypes.keySet()) {
            result.put(recordTypeId, recordTypes.get(recordTypeId).name);
        }
        return result;
    }

    /**
     * Get a specific field's name.
     *
     * @param sObjectName API name of the object
     * @param fieldAPIName API name of the object's field
     *
     * @return Label that is shown to the user
     */
    private String getFieldName (String sObjectName, String fieldAPIName) {
        System.debug(LoggingLevel.FINE, 'field API name: ' + fieldAPIName);
        Map<String, SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
        return fields.get(fieldAPIName).getDescribe().getLabel();
    }

    /**
     * Analysis result. Trying to replicate the structure of Database.SaveResult, with error messages and indication of
     * success or not.
     */
    public class FieldDependencyAnalysisResult {
        private String field;
        private String message;
        private Boolean success;

        public FieldDependencyAnalysisResult(String field, String message, Boolean success) {
            this.field = field;
            this.message = message;
            this.success = success;
        }

        public String getField () {
            return this.field;
        }

        public String getMessage () {
            return this.message;
        }

        public Boolean isSuccess () {
            return this.success;
        }
    }
}