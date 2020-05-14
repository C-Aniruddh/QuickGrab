import 'package:app/screens/login_page/login_existing_user.dart';
import 'package:app/screens/sign_up/chain/signup_chain_owner.dart';
import 'package:app/screens/sign_up/shop/signup_shop_owner.dart';
import 'package:app/screens/sign_up/user/signup_shopper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app/fonts.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {

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
              padding: const EdgeInsets.all(32.0),
              child: Hero(tag: "sign_up", child: Image(image: AssetImage('assets/images/existing_user.png'), width: 250, height: 250)),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Create a new account!", style: TextStyle(fontSize: 24, fontFamily: AppFontFamilies.mainFont))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(child: Text("Sign up as shopper or shop owner.", style: TextStyle(fontFamily: AppFontFamilies.mainFont))),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpShopOwner()));
                },
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text("Are you a shop owner?", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      leading: Hero(tag: "shop_signup", child: Image(image: AssetImage('assets/images/shop_owner.png'), width: 48, height: 48)),
                      subtitle: Text("Continue as a shopper", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpUser()));
                },
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text("Are you a shopper?", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      leading: Hero(tag: "new_user", child: Image(image: AssetImage('assets/images/new_user.png'), width: 48, height: 48)),
                      subtitle: Text("Continue as a shopper", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      trailing: Icon(Icons.arrow_forward_ios)),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 4, 16, 4),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpChainOwner()));
                },
                child: Card(child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(title: Text("Are you a shop chain owner?", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
                      leading: Hero(tag: "chain", child: Image(image: AssetImage('assets/images/chain.png'), width: 48, height: 48)),
                      subtitle: Text("Continue as a shop chain owner", style: TextStyle(fontFamily: AppFontFamilies.mainFont)),
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