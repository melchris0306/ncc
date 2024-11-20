public with sharing class CCESurveyController {
    // GET SURVEY RECORD DETAILS
    @AuraEnabled (cacheable = true)
    public static String getSurvey(String eventId){
        if (String.isBlank(eventId)){
            return null;
        }

        return CCESurveyControllerHelper.getSurveyHelper(eventId);
    }

    // GET SURVEY LOGO
    @AuraEnabled (cacheable = true)
    public static String getSurveyLogo(String code){
        if (String.isBlank(code)){
            return null;
        }

        return CCESurveyControllerHelper.getSurveyLogo(code);
    }

    // GET SURVEY FORM FIELDS
    @AuraEnabled (cacheable = true)
    public static String getSurveyFieldConfiguration(String code){
        if (String.isBlank(code)){
            return null;
        }

        return CCESurveyControllerHelper.getSurveyFieldConfiguration(code);
    }

    @AuraEnabled (cacheable = true)
    public static Contact getParticipantDetails(String participantNumber, String participantEmail, Boolean isStandalone){
        if (String.isBlank(participantNumber) || String.isBlank(participantEmail)){
            return null;
        }

        return CCESurveyControllerHelper.getParticipantDetails(participantNumber, participantEmail, isStandalone);
    }

    // CREATE SURVEY RESPONSE RECORD
    @AuraEnabled
    public static void createResponse(String eventId, String formDetailAnswers, String surveyQuestionAnswers, String participantNumber, Boolean isStandalone){
        if (String.isNotBlank(eventId) && String.isNotBlank(formDetailAnswers) && String.isNotBlank(surveyQuestionAnswers)){
            CCESurveyControllerHelper.createResponseHelper(eventId, formDetailAnswers, surveyQuestionAnswers, participantNumber, isStandalone);
        } else {
            throw new AuraHandledException('Please check your inputs.');
        }
    }

    // GET SURVEY ANSWERS
    @AuraEnabled (cacheable = true)
    public static String getSurveyAnswers(String surveyResponseId){
        if (String.isBlank(surveyResponseId)) return null;
        return CCESurveyControllerHelper.getSurveyAnswersHelper(surveyResponseId);
    }
    
    /* Updated by Xen Reyes CCN-822 Nov012021 */
    // GET SURVEY PAGE TITLE
    @AuraEnabled (cacheable = true)
    public static String getEventDetails(String eventId){
        if (String.isBlank(eventId)){
            return null;
        }

        return CCEHeroController.getEventDetails(eventId).surveyPageTitle;
    }
}