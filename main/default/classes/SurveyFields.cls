/** 
 * Serves as a wrapper class for the survey field attributes
*/
public class SurveyFields{
    @AuraEnabled public String key {get;set;}
    @AuraEnabled public String label {get;set;}
    @AuraEnabled public String apiName {get;set;}
    @AuraEnabled public String objectName {get;set;}
    @AuraEnabled public Integer order {get;set;}
    @AuraEnabled public String messageWhenRequired {get;set;}
    @AuraEnabled public String column {get;set;}
    @AuraEnabled public String fieldType {get;set;}
    @AuraEnabled public List<PicklistOptions> picklistOptions {get;set;}

    @AuraEnabled public Boolean isRequired {get;set;}
    @AuraEnabled public Boolean isSelected {get;set;}

    //used in SurveyFieldPickerController
    public SurveyFields(String label, String apiName, String objectName, Integer order, Boolean isRequired, Boolean isSelected){
        this.label = label;
        this.apiName = apiName;
        this.objectName = objectName;
        this.order = order;
        this.isRequired = isRequired;
        this.isSelected = isSelected;
    }
    
    //used to display the fields in the survey page
    public SurveyFields(String label, String apiName, String objectName, Integer order, String messageWhenRequired,
                        String column, String fieldType, Boolean isRequired){
        this.label = label;
        this.apiName = apiName;
        this.objectName = objectName;
        this.order = order;
        this.messageWhenRequired = messageWhenRequired;
        this.column = column;
        this.fieldType = fieldType;
        this.isRequired = isRequired;
        this.key = objectName + '|' + apiname;
        this.picklistOptions = new List<PicklistOptions>();
    }

    public class PicklistOptions {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}

        public PicklistOptions(String value, String label){
            this.value = value;
            this.label = label;
        }
    }
}