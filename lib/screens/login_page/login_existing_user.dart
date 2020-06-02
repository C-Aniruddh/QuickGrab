import 'package:app/screens/sign_up/user/signup_shopper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/fonts.dart';

import '../sign_up/signup_page.dart';

class LoginPageExistingUser extends StatefulWidget {
  LoginPageExistingUser({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LoginPageExistingUserState createState() => _LoginPageExistingUserState();
}

class _LoginPageExistingUserState extends State<LoginPageExistingUser> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }



  _showInfoDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Container(
                child: Text(text),
              ),
            ),
            actions: <Widget>[
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OKAY',
                ),
              ),
            ],
          );
        });
  }

  _showLoginDialog(BuildContext context, String text) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Text(text),
                  ),
                ],
              ),
            ),
          );
        });
  }


  Future<String> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    //_showLoginDialog(context, "Logging you in...");
    final GoogleSignInAuthentication googleSignInAuthentication =
    await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await FirebaseAuth.instance.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInWithGoogle succeeded: $user';
  }

  Future<String> signInWithFacebook() async {
    var facebookLogin = new FacebookLogin();
    //_showLoginDialog(context, "Logging you in...");
    var result = await facebookLogin.logIn(['email', 'public_profile']);

    FirebaseUser user;

    if (result.status == FacebookLoginStatus.loggedIn){
      FacebookAccessToken facebookAccessToken = result.accessToken;
      AuthCredential authCredential = FacebookAuthProvider.getCredential(accessToken: facebookAccessToken.token);

      user = (await FirebaseAuth.instance.signInWithCredential(authCredential)).user;
    }

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
    assert(user.uid == currentUser.uid);

    return 'signInWithGoogle succeeded: $user';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Image(image: AssetImage('assets/images/login_screen.png'), height: 250, width: 300,),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Welcome to QuickGrab!", style: TextStyle(fontSize: 24, fontFamily: AppFontFamilies.mainFont))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Sign in to continue.", style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: () async {
                  await signInWithFacebook();
                  //Navigator.pop(context);
                },
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text("Sign in with Facebook", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                  leading: Image(image: AssetImage('assets/images/facebook_logo.png'), height: 48, width: 48,),
                  subtitle: Text("Sign in using your Facebook account!", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                  trailing: Icon(Icons.arrow_forward_ios)),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: () async{
                  // _showLoginDialog(context, "Logging you in...");
                  await signInWithGoogle();
                  //Navigator.pop(context);
                },
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text("Sign in with Google", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      leading: Image(image: AssetImage('assets/images/g-logo.png'), height: 48, width: 48,),
                      subtitle: Text("Sign in using your google account!", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                )),
              ),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Don't have an account?", style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpPage()));
                },
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text("Create a new account", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      leading: Hero(tag: "sign_up", child: Image(image: AssetImage('assets/images/existing_user.png'), height: 48, width: 48,)),
                      subtitle: Text("Sign up using your facebook or google account", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}