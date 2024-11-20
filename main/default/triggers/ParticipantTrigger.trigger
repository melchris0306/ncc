trigger ParticipantTrigger on Participant__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  Apex_Trigger_Switch__c switchh = Apex_Trigger_Switch__c.getInstance(
    'ParticipantTrigger'
  );
  if (switchh != null && !switchh.Active__c) {
    return;
  }

  if (Trigger.isAfter && Trigger.isUpdate) {
    ParticipantTriggerHandler.onAfterUpdate(
      Trigger.new,
      Trigger.newMap,
      Trigger.old,
      Trigger.oldMap
    );
  }
  if (Trigger.isAfter && Trigger.isInsert) {
    ParticipantTriggerHandler.onAfterInsert(
      Trigger.new,
      Trigger.newMap,
      Trigger.old,
      Trigger.oldMap
    );
  }

  if (Trigger.isBefore && Trigger.isInsert) {
    ParticipantTriggerHandler.onBeforeInsert(Trigger.new);
  }
  if (Trigger.isBefore && Trigger.isUpdate) {
    ParticipantTriggerHandler.onBeforeUpdate(
      Trigger.new,
      Trigger.newMap,
      Trigger.old,
      Trigger.oldMap
    );
  }
  /*
    if(Trigger.isBefore && Trigger.isDelete){
        ParticipantTriggerHandler.onBeforeUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isDelete){
        ParticipantTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isUndelete){
        ParticipantTriggerHandler.onAfterUpdate(Trigger.new,Trigger.newMap,Trigger.old,Trigger.oldMap);
    }*/
}