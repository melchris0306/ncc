/*******************************************************************************************
 * @description       : CustomKanbanBoardController
 * @author            : 
 * @group             : 
 * @version    1.0   ??           		??                  ??
* 	 		   2.0   09-16-2022			Aaron David	        [CAPM-408] - Added "with sharing" class definition
*********************************************************************************************/
public with sharing class CustomKanbanBoardController {

    private final static String ERROR_MESSAGE = 'An error has occurred. Details: ';

    @AuraEnabled
    public static String getKanbanDetailsPerRecordType (String objectName, String filterANDConditions, String filterORConditions) {
        Map<String, Integer> itemsPerRecordTypeMap = new Map<String, Integer>();
        final String QUERY_STRING = 'SELECT COUNT(Id) total, RecordType.Name recordTypeName, RecordTypeId recordTypeId FROM ' + objectName 
                                        + getConditionString(filterANDConditions, 'AND')
                                        + getConditionString(filterORConditions, 'OR')
                                        + ' GROUP BY RecordType.Name, RecordTypeId ORDER BY RecordType.Name LIMIT 50000';
        
        try {
            System.debug('@@ QUERY_STRING >>' + QUERY_STRING);
            for (AggregateResult result : Database.query(QUERY_STRING)){
                itemsPerRecordTypeMap.put(String.valueOf(result.get('recordTypeName')) + '|' + String.valueOf(result.get('recordTypeId')), Integer.valueOf(result.get('total')));
            }
        } catch (QueryException e){
            throw new AuraHandledException(ERROR_MESSAGE + e.getMessage()); 
        }

        return JSON.serialize(itemsPerRecordTypeMap);
    }
    
    @AuraEnabled
    public static List<sObject> getKanbanDetails (String objectName, String objectFields, String columnFieldSource, 
                                                    String filterANDConditions, String filterORConditions,String sortByField) {
        List<sObject> sObjectList = new List<sObject>();

        if (String.isNotBlank(objectName) && String.isNotBlank(objectFields) && String.isNotBlank(columnFieldSource)){
            String query = 'SELECT Id, ';
            Map<String, Boolean> objectFieldMap = (Map<String, Boolean>) JSON.deserialize(objectFields, Map<String, Boolean>.class);
    
            for(String fieldName : objectFieldMap.keySet()){
                query += fieldName + ' ,';
    
                if (objectFieldMap.get(fieldName) && fieldName.endsWith('__r.Name')){
                    query += fieldName.replace('__r.Name', '__c') + ' ,';
                }
            }

            query = query.removeEnd(',');
            query += ' FROM ' + objectName;
            query += getConditionString(filterANDConditions, 'AND');
            query += getConditionString(filterORConditions, 'OR');

            if (String.isNotBlank(sortByField)){
                sortByField = String.escapeSingleQuotes(sortByField);
                query += ' ORDER BY ' + sortByField;
            }
			system.debug('Query string:::::::::: '+query);
            try {
                sObjectList = Database.query(query);
            } catch (QueryException e) {
                throw new AuraHandledException(ERROR_MESSAGE + e.getMessage()); 
            }
            
        }
        
        return sObjectList;
    }
    
    /*******************************************************************************************
    * @description updateStatus
    * @author adavid@ulapp.co | 09-16-2022 
    * @param recordId 
    * @param kanbanField 
    * @param kanbanNewValue 
    * @return String 

    * @version    1.0   ??           		??                  ??
    * 	 		  2.0   09-16-2022			Aaron David	        [CAPM-408] - Added DML Check before performing DML
    *********************************************************************************************/
    @AuraEnabled
    public static String updateStatus (Id recordId, String kanbanField, String kanbanNewValue) {
        SObject objectToUpdate = recordId.getSObjectType().newSObject(recordId);
        objectToUpdate.put(kanbanField, kanbanNewValue);
        Schema.DescribeSObjectResult recordDescribeSObjectResult = recordId.getSObjectType().getDescribe();
        Boolean isKanbanFieldUpdateable = Schema.getGlobalDescribe().get(recordDescribeSObjectResult.getName()).getDescribe().fields.getMap().get(kanbanField).getDescribe().isUpdateable(); 
        try {
            if (recordDescribeSObjectResult.isUpdateable() && isKanbanFieldUpdateable){
                update objectToUpdate;
            }
            
        } catch (DMLException e){
            throw new AuraHandledException(ERROR_MESSAGE + e.getMessage());   
        }
        
        return 'success';
    }

    private static String getConditionString (String filterConditions, String joinType){
        String conditionString = joinType == 'AND' ?  ' WHERE (' : ' AND (';

        if (String.isNotBlank(filterConditions)){
            Map<String, String> conditionMap = (Map<String, String>) JSON.deserialize(filterConditions, Map<String, String>.class);
            String condition = '';
      
            for (String fieldName : conditionMap.keySet()){
                String value = conditionMap.get(fieldName);
                Boolean isBoolean = value == 'true' || value == 'false';
                condition += String.isNotBlank(condition) ? ' ' + joinType + ' ' : '';
                condition += fieldName + (isBoolean ? value : '\'' + value + '\'');
            }

            if (String.isNotBlank(condition)){
                conditionString += condition + ')';
            } else {
                conditionString = '';
            }
        } else {
            conditionString = '';
        }

        return conditionString;
    }
}