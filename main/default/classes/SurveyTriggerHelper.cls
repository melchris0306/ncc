public with sharing class SurveyTriggerHelper {
    
    public static void checkExistingActiveSurveys(List<Survey__c> surveys){
        Map<Id, Survey__c> eventIdSurveyMap = new Map<Id, Survey__c>();
        for (Survey__c s : surveys){
            eventIdSurveyMap.put(s.Event__c, s);
        }

        Map<Id, Integer> campaignCountChildrenSurveyMap = new Map<Id, Integer>();
        for (Event__c c: [SELECT Id, (SELECT Id FROM Surveys__r WHERE Active__c = TRUE) FROM Event__c WHERE Id IN: eventIdSurveyMap.keySet()]){
            campaignCountChildrenSurveyMap.put(c.Id, c.Surveys__r.size());
        }

        for (Id campaignId : campaignCountChildrenSurveyMap.keySet()){
            if (campaignCountChildrenSurveyMap.get(campaignId) > 0){
                eventIdSurveyMap.get(campaignId).Active__c.addError('This event/session already has an active survey. Each event/session can only have 1 active survey at a time. Please check again.');
            }
        }
    }

    public static void setSurveyCode(List<Survey__c> surveyList){
        final String COMMUNITY_URL = getCommunityURL();

        for (Survey__c survey : surveyList){
            if (String.isBlank(survey.Survey_Code__c) && String.isBlank(survey.Event__c)){
                final String SURVEY_CODE = generateCode();
                survey.Survey_Code__c = SURVEY_CODE;
                survey.Standalone_Survey_URL__c = COMMUNITY_URL + '/s/surveys?code=' + SURVEY_CODE;
            } else if (String.isNotBlank(survey.Event__c)){
                survey.Survey_Code__c = '';
                survey.Standalone_Survey_URL__c = '';
            }
        }
    }

    //XEN REYES CCN-SUR-3235-DV 14 July 2023
    public static void setSiteValues(List<Survey__c> surveyList){

        Set<Id> campaignToGet = new Set<Id>();
        Set<Id> eventToGet = new Set<Id>();
        for (Survey__c survey : surveyList){
            if (String.isBlank(survey.Event__c) && String.isNotBlank(survey.Survey_Campaign__c)){
                campaignToGet.add(survey.Survey_Campaign__c);
            } else if (String.isNotBlank(survey.Event__c)){
                eventToGet.add(survey.Event__c);
            }
        }

        Map<Id, Campaign__c> campaignMap = new Map<Id, Campaign__c>([SELECT Id, Site_Picklist_Values__c FROM Campaign__c WHERE Id IN: campaignToGet]);
        Map<Id, Event__c> eventMap = new Map<Id, Event__c>([SELECT Id, Site_Picklist_Values__c FROM Event__c WHERE Id IN: eventToGet]);

        for (Survey__c survey : surveyList){
            if (String.isBlank(survey.Event__c) && String.isNotBlank(survey.Survey_Campaign__c)){
                survey.Site_Picklist_Values__c = campaignMap.containsKey(survey.Survey_Campaign__c) ? campaignMap.get(survey.Survey_Campaign__c).Site_Picklist_Values__c : null;
            } else if (String.isNotBlank(survey.Event__c)){
                survey.Site_Picklist_Values__c = eventMap.containsKey(survey.Event__c) ? eventMap.get(survey.Event__c).Site_Picklist_Values__c : null;
            }
        }
    }

    private static String generateCode(){
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        
        String token = '';
        while (token.length() <= 10) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            token += chars.substring(idx, idx + 1);
        }
        
        return token;
    }

    private static String getCommunityURL(){
        if (!Test.isRunningTest()){
            Network myNetwork = [SELECT Id FROM Network WHERE Name = 'Compass'];
            ConnectApi.Community  myCommunity = ConnectApi.Communities.getCommunity(myNetwork.id);
            return myCommunity.siteUrl ;
        } else {
            return 'some random url';   
        }
    }
}