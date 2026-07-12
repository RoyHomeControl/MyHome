C:\"Program Files"\Android\"Android Studio"\jbr\bin\keytool -genkeypair -v -keystore myhome-release.keystore -alias myhome -keyalg RSA -keysize 2048 -validity 10000

# 질문 - 응답 쌍
# 
# myhome
# RoyHomeControl
# RoyHomeControl
# Yongin
# Gyeonggyi
# KR

# 이후 keystore를 GitHub Secret으로 저장
#
# 1. 파일을 Base64로 변환
# [Convert]::ToBase64String([System.IO.File]::ReadAllBytes("myhome-release.keystore"))
# 2. 출력된 긴 문자열을 복사, Repository > Settings > Secrets and variables > Actions > New repository secret
# 추가:
#
# Name: MYHOME_KEYSTORE
# Value: (복사한 긴 문자열)
#
# Name: KEY_ALIAS
# Value: myhome
#
# Name: KEY_PASSWORD
# Value: 그거
#
# Name: STORE_PASSWORD
# Value: 그거

# 3. android/app/build.gradle.kts에서 아래 코드 추가
# def keystorePropertiesFile = rootProject.file("key.properties")
# def keystoreProperties = new Properties()

# if (keystorePropertiesFile.exists()) {
#     keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
# }

# 4. 기존 buildTypes... 부분의 코드에 signingConfig를 release로 변경
# 5. docker.yml에 keystore 생성하는 부분 추가


