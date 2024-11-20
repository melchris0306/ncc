/*	Created by: Allen Francisco
 *  Date:		Feb, 10, 2021
 *  Desc:		Handler class for JourneyTrigger
 */
public class JourneyTriggerHandler {
  /*	Created by: Allen Francisco
   *  Date:		Feb, 10, 2021
   *  Desc:		Populates Journey URL for compass.
   *  Revision: Make sure Journey URL is always generated when cloning
   */
  public static void populateJourneyURL(List<Journey__c> journeyList) {
    String journeyURL = getCommunityURL(
      JourneyCommunitySettings.Community_Name__c
    );
    List<Journey__c> dataToUpdate = new List<Journey__c>();
    for (Journey__c journey : journeyList) {
      //      if (journey.Journey_Preview_URL__c == null) {
      dataToUpdate.add(
        new Journey__c(
          Id = journey.Id,
          Journey_Preview_URL__c = journeyURL +
            '/s/journey?journeyId=' +
            journey.Id
        )
      );
      //      }
    }

    if (!dataToUpdate.isEmpty()) {
      if (
        FlsUtils.isUpdateable(
          dataToUpdate[0],
          new List<String>{ 'Journey_Preview_URL__c' }
        )
      ) {
        update dataToUpdate;
      }
    }
  }

  public static String getCommunityURL(String communityName) {
    if (!Test.isRunningTest()) {
      Network myNetwork = [SELECT Id FROM Network WHERE Name = :communityName];
      ConnectApi.Community myCommunity = ConnectApi.Communities.getCommunity(
        myNetwork.Id
      );
      return myCommunity.siteUrl;
    } else {
      return 'some random url';
    }
  }
  public static JourneyCommunitySettings__c JourneyCommunitySettings {
    get {
      if (JourneyCommunitySettings == null)
        JourneyCommunitySettings = JourneyCommunitySettings__c.getOrgDefaults();
      return JourneyCommunitySettings;
    }
    set;
  }
}