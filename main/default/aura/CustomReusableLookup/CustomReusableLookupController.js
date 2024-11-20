({
  onfocus: function (component, event, helper) {
    $A.util.addClass(component.find("mySpinner"), "slds-show");

    let forOpen = component.find("searchRes");
    $A.util.addClass(forOpen, "slds-is-open");
    $A.util.removeClass(forOpen, "slds-is-close");

    let getInputkeyWord = "";
    helper.searchHelper(component, event, getInputkeyWord);
  },

  onblur: function (component, event, helper) {
    component.set("v.listOfSearchRecords", null);
    let forclose = component.find("searchRes");
    $A.util.addClass(forclose, "slds-is-close");
    $A.util.removeClass(forclose, "slds-is-open");
  },

  keyPressController: function (component, event, helper) {
    let getInputkeyWord = component.get("v.searchKeyword");

    if (getInputkeyWord.length > 0) {
      var forOpen = component.find("searchRes");
      $A.util.addClass(forOpen, "slds-is-open");
      $A.util.removeClass(forOpen, "slds-is-close");
      helper.searchHelper(component, event, getInputkeyWord);
    } else {
      component.set("v.listOfSearchRecords", null);
      var forclose = component.find("searchRes");
      $A.util.addClass(forclose, "slds-is-close");
      $A.util.removeClass(forclose, "slds-is-open");
    }
  },

  handleSelectedRecord: function (component, event, helper) {
    let selectedRecordFromEvent = event.getParam("selectedRecord");
    let selectedRecordList = component.get("v.listOfSelectedRecords");

    const result = selectedRecordList.find(
      (x) => x.Id === selectedRecordFromEvent.Id
    );

    if (!result) {
      selectedRecordList.push(selectedRecordFromEvent);
      component.set("v.listOfSelectedRecords", selectedRecordList);
    }

    component.set("v.searchKeyword", "");

    var forclose = component.find("searchRes");
    $A.util.addClass(forclose, "slds-is-close");
    $A.util.removeClass(forclose, "slds-is-open");
  }
});