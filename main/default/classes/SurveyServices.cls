/*
 * @filename        : SurveyServices
 * @created         : 01.19.2021
 * @author          : JL
 * @description     : Service Class for Survey__c
 */
public with sharing class SurveyServices {
  public static String CLONED_SURVEY_NAME_IDENTIFIER = 'Copy of';
  public static String CLONED_SUCCESS_MESSAGE = 'survey cloned successfully';
  public static String GET_RECORD_FAIL_MESSAGE = 'record not found';
  public static String GET_RECORD_SUCCESS_MESSAGE = 'record found';

  @AuraEnabled
  public static Map<String, Object> getSurveyDetails(Id surveyId) {
    Map<String, Object> returnData = new Map<String, Object>();
    Boolean hasError = true;
    String message = GET_RECORD_FAIL_MESSAGE;
    List<Survey__c> soqlResults = new List<Survey__c>();
    if (
      surveyId != null &&
      surveyId.getSobjectType() == Schema.Survey__c.SObjectType
    ) {
      if (
        FlsUtils.isAccessible(
          'Survey__c',
          new List<String>{
            'Name',
            'Active__c',
            'Survey_Campaign__c',
            'Disclaimer__c',
            'Event__c',
            'Logo_Image_Id__c',
            'OwnerId',
            'Survey_Logo__c',
            'Survey_Logo_URL__c'
          }
        )
      ) {
        soqlResults = [
          SELECT
            Id,
            Name,
            Active__c,
            Survey_Campaign__c,
            Disclaimer__c,
            Event__c,
            Logo_Image_Id__c,
            OwnerId,
            Survey_Logo__c,
            Survey_Logo_URL__c,
            (
              SELECT
                Id,
                Name,
                Description__c,
                Max_Value__c,
                Min_Value__c,
                Options__c,
                Question_Type__c,
                Sorting_Order__c,
                Step__c,
                Survey__c
              FROM Survey_Questions__r
            )
          FROM Survey__c
          WHERE Id = :surveyId
        ];
      }
      if (!soqlResults.isEmpty()) {
        hasError = false;
        returnData.put('data', soqlResults[0]);
        message = GET_RECORD_SUCCESS_MESSAGE;
      }

      returnData.put('hasError', hasError);
      returnData.put('message', message);
    }

    return returnData;
  }

  @AuraEnabled
  public static String cloneSurvey(
    Id surveyId,
    Survey__c newRecord,
    Boolean setToActive,
    Boolean addClonePrefix
  ) {
    String message = '';

    if (surveyId != null) {
      Survey__c surveyToClone = new Survey__c();
      if (
        FlsUtils.isAccessible(
          'Survey__c',
          new List<String>{
            'Name',
            'Active__c',
            'Survey_Campaign__c',
            'Disclaimer__c',
            'Event__c',
            'Logo_Image_Id__c',
            'OwnerId',
            'Survey_Logo__c',
            'Survey_Logo_URL__c'
          }
        )
      ) {
        surveyToClone = [
          SELECT
            Id,
            Name,
            Active__c,
            Survey_Campaign__c,
            Disclaimer__c,
            Event__c,
            Logo_Image_Id__c,
            OwnerId,
            Survey_Logo__c,
            Survey_Logo_URL__c,
            (
              SELECT
                Id,
                Name,
                Description__c,
                Max_Value__c,
                Min_Value__c,
                Options__c,
                Question_Type__c,
                Sorting_Order__c,
                Step__c,
                Survey__c
              FROM Survey_Questions__r
            )
          FROM Survey__c
          WHERE Id = :surveyId
        ];
      }

      //deep clone survey
      Survey__c clonedSurvey = surveyToClone.clone(false, true, false, false); //clone(preserveId, isDeepClone, preserveReadonlyTimestamps, preserveAutonumber)
      if (newRecord != null) {
        clonedSurvey.Name = addClonePrefix
          ? CLONED_SURVEY_NAME_IDENTIFIER + newRecord.Name
          : newRecord.Name;
        clonedSurvey.Event__c = newRecord.Event__c;
        clonedSurvey.Active__c = newRecord.Active__c;
        clonedSurvey.Disclaimer__c = newRecord.Disclaimer__c;
      }

      //deep clone questions
      List<Survey_Question__c> clonedQuestions = new List<Survey_Question__c>();
      if (!surveyToClone.Survey_Questions__r.isEmpty()) {
        for (
          Survey_Question__c questionToClone : surveyToClone.Survey_Questions__r
        ) {
          Survey_Question__c clonedQuestion = questionToClone.clone(
            false,
            true,
            false,
            false
          ); //clone(preserveId, isDeepClone, preserveReadonlyTimestamps, preserveAutonumber)
          clonedQuestions.add(clonedQuestion);
        }
      }

      // Create a savepoint before insert cloned survey
      Savepoint sp = Database.setSavepoint();
      try {
        if (clonedSurvey != null) {
          if (
            FlsUtils.isCreateable(
              clonedSurvey,
              new List<String>{
                'Name',
                'Event__c',
                'Active__c',
                'Disclaimer__c'
              }
            )
          ) {
            insert clonedSurvey;
          }
        }

        if (!clonedQuestions.isEmpty()) {
          for (Survey_Question__c clonedQuestion : clonedQuestions) {
            clonedQuestion.Survey__c = clonedSurvey.Id;
          }

          if (
            FlsUtils.isCreateable(
              clonedQuestions.get(0),
              new List<String>{ 'Survey__c' }
            )
          ) {
            insert clonedQuestions;
          }
        }

        message = CLONED_SUCCESS_MESSAGE + '|' + clonedSurvey.Id;
      } catch (Exception e) {
        message = e.getMessage();
        // Rollback to the previous null value
        Database.rollback(sp);
      }
    }

    return message;
  }

  @AuraEnabled
  public static PrefixObjectAndFieldWrapper fetchObjectAndFieldPrefix() {
    PrefixObjectAndFieldWrapper prefObjField = new PrefixObjectAndFieldWrapper();
    try {
      prefObjField.surveyObjectPrefix = FlsUtils.applyPrefixToObject(
        'Survey__c'
      );
      Schema.DescribeSObjectResult[] dResult = Schema.describeSObjects(
        new List<String>{ prefObjField.surveyObjectPrefix }
      );

      prefObjField.activeFieldPrefix = FlsUtils.applyPrefixToField(
        dResult[0],
        'Active__c'
      );
      prefObjField.eventFieldPrefix = FlsUtils.applyPrefixToField(
        dResult[0],
        'Event__c'
      );
      prefObjField.disclaimerFieldPrefix = FlsUtils.applyPrefixToField(
        dResult[0],
        'Disclaimer__c'
      );
      prefObjField.errorMsg = '';
    } catch (Exception e) {
      prefObjField.errorMsg = e.getMessage();
    }
    return prefObjField;
  }

  public class PrefixObjectAndFieldWrapper {
    @AuraEnabled
    public String surveyObjectPrefix { get; set; }
    @AuraEnabled
    public String activeFieldPrefix { get; set; }
    @AuraEnabled
    public String eventFieldPrefix { get; set; }
    @AuraEnabled
    public String disclaimerFieldPrefix { get; set; }
    @AuraEnabled
    public String errorMsg { get; set; }
  }
}