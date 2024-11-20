/*************************************************************************************************************
 * @name            UTIL_ErrorConstants
 * @author          divinobrinas <dbrinas@ulapp.co>
 * @created         2022-02-23
 * @description     [CCN1172] UTIL Class for saving constant values used across classes for Error Handling.
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 *              No.     Date            Author                  Description
 *              ----    ------------    --------------------    ----------------------------------------------
 * @version     1.0     2022-02-23      divinobrinas            Initial version
 *
**************************************************************************************************************/
public with sharing class UTIL_Constants {
    public static final String ORG_ID = String.valueof(UserInfo.getOrganizationId());
    public static final String APP = 'CCN';
}