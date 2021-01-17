import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:justwatch_but_faster/models/setting.dart';
import 'package:justwatch_but_faster/models/provider.dart';
import 'package:justwatch_but_faster/services/fetchService.dart';
import 'package:justwatch_but_faster/services/sqlDbProvider.dart';

class SettingsView extends StatefulWidget {

  @override
  _SettingsViewState createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Future<List<Provider>> _providersFuture;

  @override
  void initState(){
    super.initState();

    _providersFuture = fetchProvider();
  }

  @override
  Widget build(BuildContext context){
    return Container(
      child: FutureBuilder<List<Provider>>(
        future: _providersFuture,
        builder: (context, snapshot){
          if (snapshot.hasError) return Text(snapshot.error);
          return snapshot.hasData
              ? _buildProvider(snapshot.data)
              : Center(child: CircularProgressIndicator(),);
        },
      ),
    );
  }

  Widget _buildProvider(List<Provider> _providerList){
    return ListView.builder(
      padding: const EdgeInsets.all(8),
        itemCount: _providerList.length,
        itemBuilder: (BuildContext context, int index){
        Provider _provTemp = _providerList[index];
        return Card(
          child: ListTile(
            leading: Image.network("https://images.justwatch.com" + _provTemp.iconUrl),
            title: Text(_provTemp.clearName),
            subtitle: Column(
              children: <Widget>[
                _preBuildSetting(_provTemp),
              ],
            ),
          ),
        );
        }
    );
  }

  Widget _preBuildSetting(Provider _provTemp){
    return FutureBuilder<Setting>(
      future: SQLiteDbProvider.db.getSettingById(_provTemp.shortName),
        builder: (context, snapshot){
        if(snapshot.hasError) return Text(snapshot.error);
        return snapshot.hasData
            ? SwitchBox(setting: snapshot.data, provider: _provTemp,) //Text(snapshot.data.id)
            : Center(child: CircularProgressIndicator(),);
        }
    );
  }
}


class SettingsViewOLD extends StatefulWidget {
  SettingsViewOLD({Key key}) : super (key: key);

  @override
  _SettingsView createState() => _SettingsView();
}

class _SettingsView extends State<SettingsViewOLD> {
  _SettingsView();

  Future<List<Setting>> settings;
  Future<Setting> setting;
  Future<Setting> themeSetting;

  @override
  void initState() {
    super.initState();
    // settings = SQLiteDbProvider.db.getAllSettings();
    //setting = SQLiteDbProvider.db.getSettingById("temperature_unit");
    //themeSetting = SQLiteDbProvider.db.getSettingById("theme_light_dark");
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(2),
        child: Column(
          children: <Widget>[
            Flexible(
              child:Text('providers'),
            ),
            Expanded(child:
            FutureBuilder<List<Provider>>(
              future: fetchProvider(),
                builder: (context, snapshot){
                if(snapshot.hasError) return Text(snapshot.error);
                return snapshot.hasData
                    ? _MyProviders(providers: snapshot.data,) // Text(snapshot.data.toString())
                    : Center(
                  child: CircularProgressIndicator(),
                );
                }
            )
                ),
          ],
        ),
      ),
    );
  }
}

class _MyProviders extends StatefulWidget{
  final List<Provider> providers;
  _MyProviders({Key key, this.providers}) : super (key: key);

  @override
  _MyProvidersState createState() => _MyProvidersState(providers: providers);
}

class _MyProvidersState extends State<_MyProviders>{
  final List<Provider> providers;
  _MyProvidersState({Key key, this.providers});

  final mySettings = SettingBloc();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(child:buildProviderList(providers)
        ),
      ],
    ) ;
  }

  Widget buildProviderList(List<Provider> _providerList){
    return Container(child:
      ListView.builder(
      padding: const EdgeInsets.all(8),
        itemCount: _providerList.length,
      itemBuilder: (BuildContext context, int index){
        return Text(_providerList[index].shortName); // _cardProvider(_providerList[index]); //  Text(_providerList[index].shortName);
      },
    ));
  }

  Widget _cardProvider(Provider _provider){
    return Card(
      child: FutureBuilder<Setting>(
        future: SQLiteDbProvider.db.getSettingById(_provider.id.toString()),
        builder: (context, snapshot){
          if (snapshot.hasError) Text(snapshot.error);
          return snapshot.hasData
              ? _combineView(_provider, snapshot.data)
              : Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _combineView(Provider _provider, Setting setting){
    return SwitchBox(setting: setting, provider: _provider,); // Text(_provider.shortName);
  }
}

class SwitchBox extends StatefulWidget {
  Setting setting;
  final Provider provider;
  SwitchBox({Key key, this.setting, this.provider});

  @override
  _SwitchBoxState createState() => _SwitchBoxState(setting: setting, provider: provider);
}

class _SwitchBoxState extends State<SwitchBox> {
  Setting setting;
  final Provider provider;
  
  final mySettings = SettingBloc();

  _SwitchBoxState({Key key, this.setting, this.provider});

  int _intensity;

  bool _isSwitch;

  @override
  void initState(){
    super.initState();
    _intensity = setting.attribute == null ? 0 : 1;
    _isSwitch = setting.attribute == null ? false : true;
  }

  void _saveInDb(){
    mySettings.add(Setting(
        provider.shortName, 'provider', DateTime.now()
    ));
    SQLiteDbProvider.db.insertSetting(Setting(
        provider.shortName, 'provider', DateTime.now()
    ));
  }

  void _setIntensityAsNull() {
    setState(() {
      _intensity = 0;
      mySettings.delete(setting.id);
    });
  }

  void _setIntensityAsOne() {
    setState(() {
      _intensity = 1;
      _saveInDb();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
          value: _isSwitch,
          onChanged: (value) {
            setState(() {
              _isSwitch = value;
              value ? _setIntensityAsOne() : _setIntensityAsNull();
            });
          },
    );
  }
}

class SettingBloc{
  SettingBloc(){
    getAllSettings();
  }

  final _settingController = StreamController<List<Setting>>.broadcast();

  get settings => _settingController.stream;

  dispose(){
    _settingController.close();
  }

  getAllSettings() async{
    _settingController.sink.add(await SQLiteDbProvider.db.getAllSettings());
  }

  delete(String id){
    SQLiteDbProvider.db.deleteSetting(id);
    getAllSettings();
  }

  add(Setting setting){
    SQLiteDbProvider.db.insertSetting(setting);
    getAllSettings();
  }

  getSettingById(String id){
    SQLiteDbProvider.db.getSettingById(id);
  }
}