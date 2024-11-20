@IsTest
private class DoNothingTest {
    @IsTest 
    private static void doNothingApexTest(){
        Test.startTest();
            DoNothing.doNothingApex();
        Test.stopTest();
        System.assert(true);
    }
}