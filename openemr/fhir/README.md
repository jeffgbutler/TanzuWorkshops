# Access the Persistent Volume

mkdir ~/temp/openemr
mount -t nfs fs1.nfs.tanzubasic.tanzuathome.net:/openemr ~/temp/openemr/

umount ~/temp/openemr

# Trust the Certificate


# Other Information

Super helpful blog post: https://community.open-emr.org/t/openemr-and-fhir/8725/8

Java FHIR implementation: https://hapifhir.io/. Possibly includes an interactive Docker based thing where we can send FHIR queries to a back end

Tool to generate patient population: https://github.com/synthetichealth/synthea

Possibly a better FHIR server than OpenEMR: https://github.com/FirelyTeam/spark

Helpful article on Oauth2 support in Spring Boot: https://www.baeldung.com/spring-webclient-oauth2

Open a shell on the cluster:

```shell
kubectl run -i --tty busybox --image=busybox -- sh
```

Open a shell in an OpenEMR pod (OpenEMR is based on Alpine):

```shell
kubectl exec --stdin --tty openemr-6fbb9f898d-dn42b -n openemr -- /bin/ash
```

# OpenEMR Setup

Logon to OpenEMR, go to Administration->Globals->Connectors. Set site address to `https://openemr.tanzuathome.net`, then enable the standard and FHIR APIs.

URL to discover what's supported in Oauth2: https://openemr.tanzuathome.net/oauth2/default/.well-known/openid-configuration

## Oauth Registration

curl -X POST -k -H 'Content-Type: application/json' -i https://openemr.tanzuathome.net/oauth2/default/registration --data '{
   "application_type": "private",
   "redirect_uris":
     ["http://localhost:8080/authorized"],
   "post_logout_redirect_uris":
     ["http://localhost:8080"],
   "client_name": "A Private App",
   "token_endpoint_auth_method": "client_secret_post",
   "contacts": ["me@example.org", "them@example.org"],
   "scope": "openid offline_access api:oemr api:fhir api:port user/allergy.read user/allergy.write user/appointment.read user/appointment.write user/dental_issue.read user/dental_issue.write user/document.read user/document.write user/drug.read user/encounter.read user/encounter.write user/facility.read user/facility.write user/immunization.read user/insurance.read user/insurance.write user/insurance_company.read user/insurance_company.write user/insurance_type.read user/list.read user/medical_problem.read user/medical_problem.write user/medication.read user/medication.write user/message.write user/patient.read user/patient.write user/practitioner.read user/practitioner.write user/prescription.read user/procedure.read user/soap_note.read user/soap_note.write user/surgery.read user/surgery.write user/vital.read user/vital.write user/AllergyIntolerance.read user/CareTeam.read user/Condition.read user/Coverage.read user/Encounter.read user/Immunization.read user/Location.read user/Medication.read user/MedicationRequest.read user/Observation.read user/Organization.read user/Organization.write user/Patient.read user/Patient.write user/Practitioner.read user/Practitioner.write user/PractitionerRole.read user/Procedure.read patient/encounter.read patient/patient.read patient/AllergyIntolerance.read patient/CareTeam.read patient/Condition.read patient/Encounter.read patient/Immunization.read patient/MedicationRequest.read patient/Observation.read patient/Patient.read patient/Procedure.read"
  }'

Response:

```json
{"client_id":"KKOMpXqy7HFvgkSq7KVEG6kNtV4sgUPHRoOsiaRfLRU","client_secret":"1goSVt63epJpkt1o0bZOgDnM4TZL3TwfoYzZneBbXaNM5xEBRdw4pulOeVeFvh_z2HJDWIJktT9ZtFzkg8O9BA","registration_access_token":"mapRIwinMxa9LquYJxZdlz-uSs09MZ9xu0uzBfex0TM","registration_client_uri":"openemr.tanzuathome.net\/oauth2\/default\/client\/gOUBbhArhHguzAnNrzKA5g","client_id_issued_at":1625604813,"client_secret_expires_at":0,"client_role":"user","contacts":["me@example.org","them@example.org"],"application_type":"private","client_name":"A
Private
App","redirect_uris":["http:\/\/localhost:8080\/authorized"],"post_logout_redirect_uris":["http:\/\/localhost:8080"],"token_endpoint_auth_method":"client_secret_post","scope":"openid
offline_access api:oemr api:fhir api:port user\/allergy.read user\/allergy.write user\/appointment.read
user\/appointment.write user\/dental_issue.read user\/dental_issue.write user\/document.read user\/document.write
user\/drug.read user\/encounter.read user\/encounter.write user\/facility.read user\/facility.write
user\/immunization.read user\/insurance.read user\/insurance.write user\/insurance_company.read
user\/insurance_company.write user\/insurance_type.read user\/list.read user\/medical_problem.read
user\/medical_problem.write user\/medication.read user\/medication.write user\/message.write user\/patient.read
user\/patient.write user\/practitioner.read user\/practitioner.write user\/prescription.read user\/procedure.read
user\/soap_note.read user\/soap_note.write user\/surgery.read user\/surgery.write user\/vital.read user\/vital.write
user\/AllergyIntolerance.read user\/CareTeam.read user\/Condition.read user\/Coverage.read user\/Encounter.read
user\/Immunization.read user\/Location.read user\/Medication.read user\/MedicationRequest.read user\/Observation.read
user\/Organization.read user\/Organization.write user\/Patient.read user\/Patient.write user\/Practitioner.read
user\/Practitioner.write user\/PractitionerRole.read user\/Procedure.read patient\/encounter.read patient\/patient.read
patient\/AllergyIntolerance.read patient\/CareTeam.read patient\/Condition.read patient\/Encounter.read
patient\/Immunization.read patient\/MedicationRequest.read patient\/Observation.read patient\/Patient.read
patient\/Procedure.read"}
```



https://openemr.tanzuathome.net/oauth2/default/authorize?response_type=code&client_id=wQn7CyGje6FJmn3Nrz9o37X0WkRAEJKNpEdU2ebWWiY&scope=patient/Patient.read&state=XPi6ZROpnjEiM36s5d6XW3PVwNfuNpptOti2p8bJrLw%3D&redirect_uri=http://localhost:8080/login/oauth2/code/openemr




curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded'
-i 'https://openemr.tanzuathome.net/oauth2/default/token'
--data 'grant_type=refresh_token
&client_id=wQn7CyGje6FJmn3Nrz9o37X0WkRAEJKNpEdU2ebWWiY
&refresh_token=def5020089a766d16...'



curl -X POST -k -H 'Content-Type: application/x-www-form-urlencoded' -i 'https://openemr.tanzuathome.net/oauth2/default/token' --data 'grant_type=password 
&client_id=X2LNX1JXNskrPw5gGYtIRjnYTyA7dH8IlRl5A 
&scope=openid%20offline_access%20api%3Aoemr%20api%3Afhir%20user%2Fallergy.read%20user%2Fallergy.write%20user%2Fappointment.read%20user%2Fappointment.write%20user%2Fdental_issue.read%20user%2Fdental_issue.write%20user%2Fdocument.read%20user%2Fdocument.write%20user%2Fdrug.read%20user%2Fencounter.read%20user%2Fencounter.write%20user%2Ffacility.read%20user%2Ffacility.write%20user%2Fimmunization.read%20user%2Finsurance.read%20user%2Finsurance.write%20user%2Finsurance_company.read%20user%2Finsurance_company.write%20user%2Finsurance_type.read%20user%2Flist.read%20user%2Fmedical_problem.read%20user%2Fmedical_problem.write%20user%2Fmedication.read%20user%2Fmedication.write%20user%2Fmessage.write%20user%2Fpatient.read%20user%2Fpatient.write%20user%2Fpractitioner.read%20user%2Fpractitioner.write%20user%2Fprescription.read%20user%2Fprocedure.read%20user%2Fsoap_note.read%20user%2Fsoap_note.write%20user%2Fsurgery.read%20user%2Fsurgery.write%20user%2Fvital.read%20user%2Fvital.write%20user%2FAllergyIntolerance.read%20user%2FCareTeam.read%20user%2FCondition.read%20user%2FCoverage.read%20user%2FEncounter.read%20user%2FImmunization.read%20user%2FLocation.read%20user%2FMedication.read%20user%2FMedicationRequest.read%20user%2FObservation.read%20user%2FOrganization.read%20user%2FOrganization.write%20user%2FPatient.read%20user%2FPatient.write%20user%2FPractitioner.read%20user%2FPractitioner.write%20user%2FPractitionerRole.read%20user%2FProcedure.read
&user_role=users
&username=admin
&password=pass'


curl -X POST 'https://192.168.139.7/apis/default/api/facility' -d \
'{
    "name": "Aquaria",
    "phone": "808-606-3030",
    "fax": "808-606-3031",
    "street": "1337 Bit Shifter Ln",
    "city": "San Lorenzo",
    "state": "ZZ",
    "postal_code": "54321",
    "email": "foo@bar.com",
    "service_location": "1",
    "billing_location": "1",
    "color": "#FF69B4"
}'



curl -X GET 'https://openemr.tanzuathome.net/apis/default/api/facility' \
  -H 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiJ2NmpmWVNLdHFLdEI2QVZFbk1mdUotWlhJWmQ4WnE1OWRhcEl3WHNock00IiwiaXNzIjoiMTkyLjE2OC4xMzkuN1wvb2F1dGgyXC9kZWZhdWx0IiwiaWF0IjoxNjI0MzczNjcwLCJleHAiOjE2MjQzNzcyNzAsInN1YiI6IjkzYmM2NDk5LTgwNmYtNDBhOS04YTlkLWRjMDNmNmM5MTlkOCIsImFwaTpvZW1yIjp0cnVlLCJhcGk6ZmhpciI6dHJ1ZX0.p4NtbG6_58xcaQV4QdmJ1SAL67zBaKf1ujG-AHaBh1rVF9ejWOE9dKmhavSeYvzc4RzpNu8epOPWlX3dn58xwyYnSL8xVDvSzkXrAxaNl95iKDi_VzTtpY9pBU2BO1BUzA73BH_d11Bv37N015Chvad-acpHnSbbIOjXY16kMGUlZ0zilefPbkituFuOJpv3Lp4SxxIRTpustAJpIloBldTwx7bZ4sRNVV7QmW1BPeURuuKRJcCF1o7MyMqRp2nmeWm0_HjFcquhHdiWJgA5hpokLXc7wcjUsYM4oMyFS_g1xxXpQntmW1XRpfSV1nSX9CHYfTTVOSJYCJq5qtZ-gg'
