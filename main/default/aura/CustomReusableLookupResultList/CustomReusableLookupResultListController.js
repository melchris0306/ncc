({
  clear: function (component, event, helper) {
    let recordList = component.get("v.listOfSelectedRecords");
    recordList.splice(event.getSource().get("v.name"), 1);
    component.set("v.listOfSelectedRecords", recordList);
  }
});