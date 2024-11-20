trigger ParkingLotTrigger on Parking_Lot__c (before insert, before update, after insert, after update) {
    new ParkingLotTriggerHandler().execute();
}