#!/bin/bash

# Скрипт для настройки LDAP в Keycloak через Admin REST API
# Выполняется после запуска Keycloak

KEYCLOAK_URL="http://localhost:8080"
REALM="reports-realm"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# Получаем access token администратора
TOKEN=$(curl -s -X POST "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${ADMIN_USER}" \
  -d "password=${ADMIN_PASSWORD}" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

# Создаём LDAP User Federation
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/user-federations/ldap" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "openldap",
    "providerId": "ldap",
    "providerType": "org.keycloak.storage.UserStorageProvider",
    "config": {
      "enabled": ["true"],
      "priority": ["0"],
      "importEnabled": ["true"],
      "editMode": ["READ_ONLY"],
      "syncRegistrations": ["false"],
      "vendor": ["other"],
      "usePasswordModifyExtension": ["false"],
      "usernameLDAPAttribute": ["uid"],
      "rdnLDAPAttribute": ["uid"],
      "uuidLDAPAttribute": ["uid"],
      "userObjectClasses": ["inetOrgPerson, organizationalPerson"],
      "connectionUrl": ["ldap://openldap:389"],
      "usersDn": ["ou=People,dc=example,dc=com"],
      "authType": ["simple"],
      "bindDn": ["cn=admin,dc=example,dc=com"],
      "bindCredential": ["admin"],
      "customUserSearchFilter": ["(objectClass=inetOrgPerson)"],
      "searchScope": ["1"],
      "validatePasswordPolicy": ["false"],
      "trustEmail": ["false"],
      "useTruststoreSpi": ["ldapsOnly"],
      "connectionPooling": ["true"],
      "connectionPoolingAuthentication": ["false"],
      "connectionPoolingDebug": ["false"],
      "connectionPoolingInitSize": ["5"],
      "connectionPoolingMaxSize": ["100"],
      "connectionPoolingPrefSize": ["10"],
      "connectionPoolingProtocol": ["TLS"],
      "connectionTimeout": [""],
      "readTimeout": [""],
      "pagination": ["true"],
      "batchSizeForSync": ["1000"],
      "fullSyncPeriod": ["604800"],
      "changedSyncPeriod": ["86400"],
      "cachePolicy": ["DEFAULT"]
    }
  }'

echo ""
echo "LDAP User Federation created"

# Создаём LDAP Mapper для групп
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/user-federations/ldap/mappers" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "group-mapper",
    "providerId": "group-ldap-mapper",
    "providerType": "org.keycloak.storage.ldap.mappers.LDAPStorageMapper",
    "config": {
      "groups.dn": ["ou=Groups,dc=example,dc=com"],
      "group.name.ldap.attribute": ["cn"],
      "group.object.classes": ["groupOfNames"],
      "membership.ldap.attribute": ["member"],
      "membership.attribute.type": ["DN"],
      "membership.user.ldap.attribute": ["uid"],
      "groups.ldap.filter": ["(objectClass=groupOfNames)"],
      "mode": ["READ_ONLY"],
      "user.roles.retrieve.strategy": ["LOAD_GROUPS_BY_MEMBER_ATTRIBUTE"],
      "memberof.ldap.attribute": ["memberOf"],
      "mapped.group.attributes": [""],
      "drop.non.existing.groups.during.sync": ["false"]
    }
  }'

echo ""
echo "LDAP Group Mapper created"

# Создаём Role Mapper для маппинга LDAP групп в Keycloak роли
curl -X POST "${KEYCLOAK_URL}/admin/realms/${REALM}/user-federations/ldap/mappers" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "role-mapper",
    "providerId": "role-ldap-mapper",
    "providerType": "org.keycloak.storage.ldap.mappers.LDAPStorageMapper",
    "config": {
      "roles.dn": ["ou=Groups,dc=example,dc=com"],
      "role.name.ldap.attribute": ["cn"],
      "role.object.classes": ["groupOfNames"],
      "membership.ldap.attribute": ["member"],
      "membership.attribute.type": ["DN"],
      "membership.user.ldap.attribute": ["uid"],
      "roles.ldap.filter": ["(objectClass=groupOfNames)"],
      "mode": ["READ_ONLY"],
      "user.roles.retrieve.strategy": ["LOAD_GROUPS_BY_MEMBER_ATTRIBUTE"],
      "memberof.ldap.attribute": ["memberOf"],
      "mapped.role.attributes": [""],
      "drop.non.existing.roles.during.sync": ["false"]
    }
  }'

echo ""
echo "LDAP Role Mapper created"

echo ""
echo "LDAP setup completed. Please sync users from Keycloak Admin Console."

