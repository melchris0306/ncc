/** 
 * This serves as the controller of surveyFieldPicker LWC
 * @author Pamela Kiang
 * @since 05/20/2021
*/
public with sharing class SurveyFieldPickerController {
    
    @testVisible
    private static List<Survey_Field_Configuration__mdt> mockFieldConfiguration = new List<Survey_Field_Configuration__mdt>();

    /** 
     * Retrieves fields that can be selected to be displayed in a survey form
     * @param surveyId - recordId of a survey
     * @return List of SurveyFields that contains attributes of the fields
    */
    @AuraEnabled(cacheable = true)
    public static List<SurveyFields> getSurveyFieldsFromMetadata(String surveyId){

        List<SurveyFields> surveyFieldList = new List<SurveyFields>();
        Map<String, Survey_Field_Configuration__mdt> surveyConfigMap = getSurveyFieldConfig();

        try {           
            Survey__c surveyRecord;
            
            if (FLSUtils.isAccessible('Survey__c', new List<String>{'Survey_Fields_JSON__c', 'Event__c'})){
                surveyRecord = [SELECT Id, Survey_Fields_JSON__c, Event__c FROM Survey__c WHERE Id = :surveyId];
            }
            
            if (surveyRecord != null){
                Boolean isSurveyForEvent = (surveyRecord.Event__c!=null);

            	if (String.isNotBlank(surveyRecord.Survey_Fields_JSON__c)){
                	Map<String, Boolean> surveyFieldConfig = (Map<String, Boolean>) JSON.deserialize(surveyRecord.Survey_Fields_JSON__c, 
                                                            Map<String, Boolean>.class);

                    for (String key : surveyConfigMap.keySet()){
                        Survey_Field_Configuration__mdt surveyField = surveyConfigMap.get(key);
    
                        if (!surveyField.Is_Event_Field__c || (isSurveyForEvent && surveyField.Is_Event_Field__c)){
                            if (surveyFieldConfig.containsKey(key)){
                                surveyFieldList.add(mapSurveyField(surveyField, surveyFieldConfig.get(key), true));
                                
                            } else {
                                surveyFieldList.add(mapSurveyField(surveyField, false, false));   
                            }
                        }
                    }
                } else {
                    for(Survey_Field_Configuration__mdt surveyField : surveyConfigMap.values()){
                        if (!surveyField.Is_Event_Field__c || (isSurveyForEvent && surveyField.Is_Event_Field__c)){
                            surveyFieldList.add(mapSurveyField(surveyField, false, false));     
                        }                              
                    }
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return surveyFieldList;
    }

    /** 
     * Updates the survey with the selected fields
     * @param selectedFields selected fields to be displayed in the survey in JSON format
     * @param surveyId record id of survey
    */
    @AuraEnabled
    public static void saveSelectedFields(String selectedFields, String surveyId){
        Survey__c surveyRecord = new Survey__c(Id = surveyId, Survey_Fields_JSON__c = selectedFields);
        try {
            if (String.isNotBlank(selectedFields) && String.isNotBlank(surveyId)
                    && FLSUtils.isUpdateable(surveyRecord, new List<String>{'Survey_Fields_JSON__c'})){
                update surveyRecord;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /** 
     * Retrieves fields that can be selected to be displayed in a survey form
     * @param surveyFieldConfig a metadata record of the field configuration
     * @param isRequired - marks the field that if it's required
     * @param isSelected - ticks the field checkbox to let admin know that the field is selected to be displayed in survey
     * @return SurveyFields - wrapped attributes of the configured fields
    */
    private static SurveyFields mapSurveyField(Survey_Field_Configuration__mdt surveyFieldConfig, Boolean isRequired, Boolean isSelected){
        return new SurveyFields(surveyFieldConfig.Label, surveyFieldConfig.Field_API_Name__c, 
                                    surveyFieldConfig.Object_API_Name__c, Integer.valueOf(surveyFieldConfig.Order__c),
                                    isRequired, isSelected); 
    }

    /** 
     * Retrieves fields saved as a configuration via custom metadata
     * @return Map<String, Survey_Field_Configuration__mdt> - Key is the combined name of object where the field belongs and its API Name
     *                                                      - Value is the metadata record
    */
    private static Map<String, Survey_Field_Configuration__mdt> getSurveyFieldConfig(){
        Map<String, Survey_Field_Configuration__mdt> surveyConfigMap = new Map<String, Survey_Field_Configuration__mdt>();
		
        //mock the metadata results to avoid dependency on actual metadata records
     	List<Survey_Field_Configuration__mdt> surveyFieldConfigList = Test.isRunningTest()
            														 ? mockFieldConfiguration
            														 : [SELECT Label, Object_API_Name__c, Field_API_Name__c, 
                                                                            Order__c, Is_Event_Field__c 
                                                                        FROM Survey_Field_Configuration__mdt 
                                                                        ORDER BY Order__c
                                                                        LIMIT 5000];
                                                                            
        for(Survey_Field_Configuration__mdt surveyField : surveyFieldConfigList){
            surveyConfigMap.put(surveyField.Object_API_Name__c + '|' + surveyField.Field_API_Name__c, surveyField);
        }

        return surveyConfigMap;
    }
}