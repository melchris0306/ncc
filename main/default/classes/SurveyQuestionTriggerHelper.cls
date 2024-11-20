public with sharing class SurveyQuestionTriggerHelper {
    
    public static void checkDuplicateSortingOrder(List<Survey_Question__c> surveyQuestions){
        List<Id> surveyIds = new List<Id>();
        for (Survey_Question__c sq : surveyQuestions){
            surveyIds.add(sq.Survey__c);
        }
        if (surveyIds.size() > 0){
            Map<Id, Set<Integer>> surveyQuestionOrderMap = new Map<Id, Set<Integer>>();
            if(FlsUtils.isAccessible('Survey_Question__c', new List<String>{'Sorting_Order__c','Survey__c'})){
                for (Survey_Question__c sq : [SELECT Sorting_Order__c, Survey__c FROM Survey_Question__c WHERE Survey__c IN: surveyIds ORDER BY Sorting_Order__c]){
                    if (surveyQuestionOrderMap.keySet().contains(sq.Survey__c)){
                        surveyQuestionOrderMap.get(sq.Survey__c).add(Integer.valueOf(sq.Sorting_Order__c));
                    } else {
                        Set<Integer> sortingOrderSet = new Set<Integer>();
                        sortingOrderSet.add(Integer.valueOf(sq.Sorting_Order__c));
                        surveyQuestionOrderMap.put(sq.Survey__c, sortingOrderSet);
                    }
                }   
            }
            if (surveyQuestionOrderMap.size() > 0){
                for (Survey_Question__c sq : surveyQuestions){
                    if (surveyQuestionOrderMap.get(sq.Survey__c).contains(Integer.valueOf(sq.Sorting_Order__c))){
                        sq.Sorting_Order__c.addError('Another question in this survey already has this order, please enter another order.');
                    }
                }   
            }
        }
    }
}