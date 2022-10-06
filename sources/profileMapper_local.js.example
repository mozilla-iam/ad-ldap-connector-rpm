module.exports = function (raw_data) {
  /* Mozilla LDAP specific aliases handling */
  var all_emails = [];
  if (raw_data.mail) {
    all_emails = all_emails.concat(raw_data.mail);
  }
  if (raw_data['zimbraAlias']) {
    all_emails = all_emails.concat(raw_data['zimbraAlias']);
  }

  var profile = {
    id:          raw_data.objectGUID || raw_data.uid || raw_data.cn,
    displayName: raw_data['cn'],
    name: {
      familyName: raw_data.sn,
      givenName: raw_data.givenName
    },
    nickname: raw_data['sAMAccountName'] || raw_data['cn'] || raw_data['commonName'],
    groups: raw_data['groups'],
    ldap_groups: raw_data['groups'],
    emails: all_emails
  };

  var HRData = {
    cost_center: raw_data['workdayCostCenter'],
    management_level: raw_data['workdayManagementLevel'],
    manager_name: raw_data['managerName'],
    manager_email: raw_data['managerEmail'],
    business_title: raw_data['workdayBusinessTitle'],
    worker_type: raw_data['workdayDetailedWorkerType'],
    test_value: 'empty'
  };

  profile['dn'] = raw_data['dn'];
  profile['st'] = raw_data['st'];
  profile['description'] = raw_data['description'];
  profile['postalCode'] = raw_data['postalCode'];
  profile['telephoneNumber'] = raw_data['telephoneNumber'];
  profile['distinguishedName'] = raw_data['distinguishedName'];
  profile['co'] = raw_data['co'];
  profile['department'] = raw_data['department'];
  profile['company'] = raw_data['company'];
  profile['mailNickname'] = raw_data['mailNickname'];
  profile['sAMAccountName'] = raw_data['sAMAccountName'];
  profile['sAMAccountType'] = raw_data['sAMAccountType'];
  profile['userPrincipalName'] = raw_data['userPrincipalName'];
  profile['manager'] = raw_data['manager'];
  profile['organizationUnits'] = raw_data['organizationUnits'];
  
  // if your LDAP service provides verified email addresses, uncomment this:
  // profile['email_verified'] = true;

  profile['email_verified'] = true; //LDAP emails are manually created through tickets, thus always verified

  // The ad-ldap-connector-rpm had always had a customized profileMapper.js which set
  // profile['email_aliases'] to contain [{value: raw_data.mail }] which is a different format
  profile['email_aliases'] = raw_data['zimbraAlias'];
  profile['_HRData'] = HRData;

  // This will make the profile huge:
  // if (raw_data['thumbnailPhoto']) {
  //   profile['picture'] = 'data:image/bmp;base64,' +
  //     raw_data['thumbnailPhoto'].toString('base64');
  // }
  return profile;
};
