({
  doInit: function (component, event, helper) {
    helper.getParticipants(component, event, helper);
  },

  saveParticipants: function (component, event, helper) {
    helper.saveParticipants(component, event, helper);
  },

  closeModal: function (component, event, helper) {
    $A.get("e.force:closeQuickAction").fire();
  }
});