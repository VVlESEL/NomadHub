import 'package:flutter/material.dart';
import 'package:nomad_hub/ui/settings/eula.dart';
import 'package:nomad_hub/utils/auth.dart';
import 'package:nomad_hub/main.dart';
import 'package:nomad_hub/ui/settings/privacy_policy.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

enum FormType { login, register, forgot }

class _LoginScreenState extends State<LoginScreen> {
  bool _isPolicyAccepted = false;
  Color _privacyPolicyColor = Colors.black;
  FormType _formType = FormType.login;
  final GlobalKey<FormState> _formKey = GlobalKey();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerPassword2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
            primaryColor: Colors.black,
            accentColor: Colors.black,
          ),
      child: Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("images/loadscreen_small.jpg"),
              fit: BoxFit.fill,
            ),
          ),
          child: Container(
            //background image filter
            color: Colors.white.withOpacity(0.65),
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    "images/icon_nomad_hub_round.png",
                    color: Colors.grey.shade700,
                    width: 100.0,
                    height: 100.0,
                  ),
                ),
                ListTile(
                  onTap: () async {
                    if(!checkPrivacyPolicy()) return;

                    bool isSignedIn;
                    await Auth.googleSignIn().then((b) {
                      isSignedIn = b;
                    });
                    if (isSignedIn) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  MainScaffold()),
                          (_) => false);
                    } else {
                      Scaffold.of(context).showSnackBar(SnackBar(
                            content: Text(
                                "Request failed! Please check your inputs and make sure you are connected to the internet."),
                            duration: Duration(milliseconds: 3000),
                          ));
                    }
                  },
                  leading: Image.asset(
                    "images/icon_google.png",
                    width: 40.0,
                    height: 40.0,
                  ),
                  title: Text("Login with Google"),
                ),
                ExpansionTile(
                  leading: Icon(
                    Icons.email,
                    size: 40.0,
                  ),
                  title: Text("Login with E-Mail"),
                  children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Builder(builder: (BuildContext context) {
                          return _formType == FormType.login
                              ? _getLoginForm(context)
                              : (_formType == FormType.register
                                  ? _getRegisterForm(context)
                                  : _getForgotForm(context));
                        }))
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: <Widget>[
                      Checkbox(
                        value: _isPolicyAccepted,
                        onChanged: (b) => setState(() => _isPolicyAccepted = b),
                      ),
                      Flexible(
                        child: Column(
                          children: <Widget>[
                            FlatButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          PrivacyPolicyScreen())),
                              child: Text(
                                "I have read and accept the privacy policy (click here to read)",
                                style: TextStyle(color: _privacyPolicyColor),
                              ),
                            ),
                            FlatButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          EulaScreen())),
                              child: Text(
                                "I have read and accept the EULA (click here to read)",
                                style: TextStyle(color: _privacyPolicyColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
          ),
          TextFormField(
            controller: _controllerEmail,
            autocorrect: false,
            validator: (value) {
              if (!value.contains("@")) return "Please enter your e-mail";
            },
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: "E-Mail",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
          ),
          TextFormField(
            controller: _controllerPassword,
            autocorrect: false,
            validator: (value) {
              if (value.isEmpty) return "Please enter your password";
            },
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              labelText: "Password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          Container(
            height: 60.0,
            decoration: BoxDecoration(
              color: Theme.of(context).buttonColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: FlatButton(
              onPressed: () async {
                if (_formKey.currentState.validate()) {
                  if(!checkPrivacyPolicy()) return;

                  bool isSingedIn;
                  await Auth
                      .emailSignIn(
                          _controllerEmail.text, _controllerPassword.text)
                      .then((b) {
                    isSingedIn = b;
                  });
                  if (isSingedIn) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => MainScaffold()),
                        (_) => false);
                  } else {
                    Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Request failed! Please check your inputs and make sure you are connected to the internet."),
                          duration: Duration(milliseconds: 3000),
                        ));
                  }
                }
              },
              child: Text("Login", style: TextStyle(fontSize: 20.0)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  _formKey?.currentState?.reset();
                  setState(() => _formType = FormType.register);
                },
                child: Text("Sign up"),
              ),
              FlatButton(
                onPressed: () {
                  _formKey?.currentState?.reset();
                  setState(() => _formType = FormType.forgot);
                },
                child: Text("Forgot password?"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getRegisterForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
          ),
          TextFormField(
            controller: _controllerEmail,
            autocorrect: false,
            validator: (value) {
              if (!value.contains("@")) return "Please enter your e-mail";
            },
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: "E-Mail",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
          ),
          TextFormField(
            controller: _controllerPassword,
            autocorrect: false,
            validator: (value) {
              if (value.length < 6)
                return "Please enter a password with at least 6 characters";
              if (value != _controllerPassword2.text)
                return "Please enter matching passwords";
            },
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              labelText: "Password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
          ),
          TextFormField(
            controller: _controllerPassword2,
            autocorrect: false,
            validator: (value) {
              if (value.length < 6)
                return "Please enter a password with at least 6 characters";
              if (value != _controllerPassword.text)
                return "Please enter matching passwords";
            },
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_outline),
              labelText: "Repeat Password",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          Container(
            height: 60.0,
            decoration: BoxDecoration(
              color: Theme.of(context).buttonColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: FlatButton(
              onPressed: () async {
                if(!checkPrivacyPolicy()) return;

                if (_formKey.currentState.validate()) {
                  bool isCreated;
                  await Auth
                      .createUser(
                          _controllerEmail.text, _controllerPassword.text)
                      .then((b) {
                    isCreated = b;
                  });
                  if (isCreated) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => MainScaffold()),
                        (_) => false);
                  } else {
                    Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text(
                              "Request failed! Please check your inputs and "
                                  "make sure you are connected to the internet. "
                                  "If you have connection the e-mail has most "
                                  "likely already been registered."),
                          duration: Duration(milliseconds: 3000),
                        ));
                  }
                }
              },
              child: Text("Sign up", style: TextStyle(fontSize: 20.0)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  _formKey?.currentState?.reset();
                  setState(() => _formType = FormType.login);
                },
                child: Text("Login"),
              ),
              FlatButton(
                onPressed: () {
                  _formKey?.currentState?.reset();
                  setState(() => _formType = FormType.forgot);
                },
                child: Text("Forgot password?"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getForgotForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 3.0),
          ),
          TextFormField(
            controller: _controllerEmail,
            autocorrect: false,
            validator: (value) {
              if (!value.contains("@")) return "Please enter your e-mail";
            },
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: "E-Mail",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
          ),
          Container(
            height: 60.0,
            decoration: BoxDecoration(
              color: Theme.of(context).buttonColor,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: FlatButton(
              onPressed: () async {
                if(!checkPrivacyPolicy()) return;

                if (_formKey.currentState.validate()) {
                  bool isSent;
                  await Auth
                      .sendPasswordResetEmail(_controllerEmail.text)
                      .then((b) {
                    isSent = b;
                  });
                  Scaffold.of(context).showSnackBar(SnackBar(
                        content: Text(
                          !isSent
                              ? "Request failed! Please check your inputs and make sure you are connected to the internet."
                              : "Reset Link was sent to ${_controllerEmail
                          .text}.",
                        ),
                        duration: Duration(milliseconds: 3000),
                      ));
                }
              },
              child: Text("Reset Password", style: TextStyle(fontSize: 20.0)),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  _formKey?.currentState?.reset();
                  setState(() => _formType = FormType.register);
                },
                child: Text("Sign up"),
              ),
              FlatButton(
                onPressed: () {
                  _formKey?.currentState?.reset();
                  setState(() => _formType = FormType.login);
                },
                child: Text("Login"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool checkPrivacyPolicy() {
    if (!_isPolicyAccepted) {
      setState(() => _privacyPolicyColor = Theme.of(context).errorColor);
      return false;
    } else {
      setState(() => _privacyPolicyColor = Colors.black);
      return true;
    }
  }
}
