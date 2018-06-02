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
public without sharing class FieldDependency {
    public String conditionOperator;
    public String conditionField;
    public String conditionValue;
    public String ruleOperator;
    public String ruleField;
    public String ruleValue;

    public String sObjectName;
    public String recordType;
    public String errorMessage;
    public String developerName;

    public FieldDependency (FieldRule__mdt dependencyMetadata) {
        this(
            dependencyMetadata.ConditionField__c,
            dependencyMetadata.ConditionOperator__c,
            dependencyMetadata.ConditionValue__c,
            dependencyMetadata.RuleField__c,
            dependencyMetadata.RuleOperator__c,
            dependencyMetadata.RuleValue__c,
            dependencyMetadata.Object__c,
            dependencyMetadata.RecordType__c,
            dependencyMetadata.ErrorMessage__c,
            dependencyMetadata.DeveloperName
        );
    }

    public FieldDependency (
        String conditionField,
        String conditionOperator,
        String conditionValue,
        String ruleField,
        String ruleOperator,
        String ruleValue,
        String sObjectName,
        String recordTypeName,
        String errorMessage,
        String developerName) {
        this.conditionField = conditionField;
        this.conditionOperator = conditionOperator;
        this.conditionValue = conditionValue;
        this.ruleField = ruleField;
        this.ruleOperator = ruleOperator;
        this.ruleValue = ruleValue;
        this.sObjectName = sObjectName;
        this.recordType = recordTypeName;
        this.errorMessage = errorMessage;
        this.developerName = developerName;
    }
}