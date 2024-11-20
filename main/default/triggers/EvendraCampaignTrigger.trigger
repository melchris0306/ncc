trigger EvendraCampaignTrigger on Campaign (before insert, before update,after insert) {
    
    EvendraCampaignTriggerHandler handler = new EvendraCampaignTriggerHandler();
    system.debug('---------- trigger was triggered');
    
    if(Trigger.isInsert && Trigger.isAfter){
        system.debug('---------- trigger was triggered');
        handler.setCampaignMemberStatusDefault(Trigger.new);
    }
    
    /* Before Insert */
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }
    
    /* Before Update */
    if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.newMap, Trigger.oldMap);
    }
    
    /* After Insert */
    
    
}