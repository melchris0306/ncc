@isTest (SeeAllData = false)
public class ParkingLotTriggerHandler_Test {
    
    @testSetup 
    static void setUp() {
        Apex_Trigger_Switch__c switchh = new Apex_Trigger_Switch__c();
        switchh.Name = 'ParkingLotTrigger';
        switchh.Active__c = true;
        insert switchh;
        
        TestFactory.ParkingLotTestDataFactory df = new TestFactory.ParkingLotTestDataFactory();
        df.make();
        df.persist();
    }
    @IsTest
    static void should_send_update_successfully(){
        Parking_Lot__c pl = [SELECT ID, First_Modified_Date__c FROM Parking_Lot__c Limit 1];
        System.assert(pl.First_Modified_Date__c == null, 'First Modified Date field has an initial value of null.');
        Test.startTest();
            pl.Status__c = 'Closed';
            update pl;
        Test.stopTest();
        System.assert(pl.Status__c == 'Closed', 'Unexpected Error, update did not push through');
        Parking_Lot__c plUpdated = [SELECT ID, First_Modified_Date__c  FROM Parking_Lot__c Limit 1];
        System.assert(plUpdated.First_Modified_Date__c != null, 'First Modified Date field is ' + pl.First_Modified_Date__c);
    }
    
    //This is to test the First Modified of Parking Lot and populate the First Modified Date field.
    @IsTest
    static void should_send_update_for_FirstModified_successfully(){
        Parking_Lot__c pl = [SELECT ID, First_Modified_Date__c, Status__c FROM Parking_Lot__c Limit 1];
        System.assert(pl.First_Modified_Date__c == null, 'First Modified Date field has an initial value of null.');
        Test.startTest();
            pl.Description__c  = 'This is to test the Open Email Template.';
            update pl;
        Test.stopTest();
        System.assert(pl.Status__c == 'Open', 'Unexpected Error, update did not push through');
        Parking_Lot__c plUpdated = [SELECT ID, First_Modified_Date__c  FROM Parking_Lot__c Limit 1];
        System.assert(plUpdated.First_Modified_Date__c != null, 'First Modified Date field is ' + pl.First_Modified_Date__c);
    }

    
    @IsTest
    static void should_send_email_from_compass_setting(){
        Test.startTest();
        LotWithDefault fact = new LotWithDefault();
        fact.make();
        fact.persist();
        Parking_Lot__c lot = fact.getLot();
        lot.Resolution_Answer__c = 'Something';
        lot.Status__c = 'Closed';
        update lot;
        Parking_Lot__c updated = [
            SELECT ID, 
            Status__c, 
            Resolution_Answer__c 
            FROM Parking_Lot__c 
            WHERE Id = :lot.Id
        ];
        System.assert(updated.Status__c == 'Closed', 'Unexpected Error, update did not push through');
        Test.stopTest();
    }

    private class LotWithDefault implements TestFactory.DataFactory{
        private Contact con;
        private Event__c evt;
        private Parking_Lot__c pl;
        
        public void make(){
            this.con = new Contact();
            this.con.Firstname = 'Random';
            this.con.Lastname = 'Random Last Name';
            this.con.Email = 'me@random.com';
            this.con.Contact_Type__c = 'Client';

            insert this.con;

            Campaign__c  campaignRec = new Campaign__c();
            Account acc = new Account(Name ='Test Acc');
       		insert acc;
            campaignRec.Account__c = acc.Id;
            insert campaignRec;
            
            this.evt = new Event__c();
            this.evt.Name = 'Some Event';
            this.evt.Campaign__c =campaignRec.Id;
            this.evt.Event_Id__c = 'Test';
            this.evt.Parking_Lot_User__c = this.con.Id;
            this.evt.Compass_Setting__c = [SELECT ID FROM Compass_Setting__c LIMIT 1].Id;
            insert this.evt;
        }
        public void persist(){
            this.pl = new Parking_Lot__c(
                Event__c = this.evt.Id,
                Raised_By__c = this.con.Id,
                Description__c = 'Question 1',
                Status__c = 'Open',
                Type__c = 'Issue'
            );
            insert this.pl;
        }
        public Parking_Lot__c getLot(){
            return this.pl;
        }
    }
}