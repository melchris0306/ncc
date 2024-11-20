/**
 * @description       : [CCN-EVE-1244-DV] CloneSessionControllerTest
 *  Test Class for CloneSessionController [CCN-EVE-1244-DV]
 * @author            : adavid@ulapp.co
 * @group             : 
 * @last modified on  : 05-30-2022
 * @last modified by  : adavid@ulapp.co
**/

@isTest
public with sharing class CloneSessionControllerTest {

    @isTest
    public static void testcloneSessionRecord(){
        
        TestFactory.CloneSessionTestDataFactory cloneSessionFactory = new TestFactory.CloneSessionTestDataFactory();
        cloneSessionFactory.make();
        cloneSessionFactory.persist();

        Test.startTest();
        System.assertNotEquals(CloneSessionController.cloneSessionRecord(cloneSessionFactory.testSessionRec.Id), null);
        Test.stopTest();
    }

    @isTest
    public static void testcloneSessionRecordError(){
        Test.startTest();
        CloneSessionController.cloneSessionRecord(null);
        Test.stopTest();
    }
}