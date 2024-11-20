({
  selectRecord: function (component, event, helper) {
    var getSelectRecord = component.get("v.recordObj");
    var parentEvent = component.getEvent("selectedRecordEvent");
    parentEvent.setParams({ selectedRecord: getSelectRecord });
    parentEvent.fire();
  }
});