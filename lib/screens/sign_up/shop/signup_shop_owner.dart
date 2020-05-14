import 'package:app/screens/sign_up/shop/signup_shop_owner_google.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/fonts.dart';

class SignUpShopOwner extends StatefulWidget {
  SignUpShopOwner({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SignUpShopOwnerState createState() => _SignUpShopOwnerState();
}

class _SignUpShopOwnerState extends State<SignUpShopOwner> {

  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      print(e); // TODO: show dialog with error
    }
  }

  Future<String> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: Hero(tag: "shop_signup", child: Image(image: AssetImage('assets/images/shop_owner.png'), height: 250, width: 300,)),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Are you a shop owner?", style: TextStyle(fontSize: 24, fontFamily: AppFontFamilies.mainFont))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Sign up as a shop!", style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: Card(child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListTile(title: Text("Phone Number", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                leading: Image(image: AssetImage('assets/images/password.png'), height: 48, width: 48,),
                subtitle: Text("Sign in with phone number", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                trailing: Icon(Icons.arrow_forward_ios)),
              )),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpShopOwnerGoogle()));
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
          ],
        ),
      ),
    );
  }
}

