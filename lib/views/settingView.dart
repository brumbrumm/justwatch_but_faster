import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:justwatch_but_faster/main.dart';
import 'package:justwatch_but_faster/models/localeChoice.dart';
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
  Future<List<LocaleChoice>> _localeFuture;
  Future<Setting> _settingFuture;

  int _indexSelected = 0;
  int _stateCheck = 0;

  @override
  void initState(){
    super.initState();

    _providersFuture = fetchProvider();
    _localeFuture = fetchLocale();
    _indexSelected = 0;
    _settingFuture = SQLiteDbProvider.db.getSettingById('locale');
  }

  @override
  Widget build(BuildContext context){
    return Column(
      children: <Widget>[
        Expanded(
          //height: 200,
          child: FutureBuilder<List<Provider>>(
            future: _providersFuture,
            builder: (context, snapshot){
              if (snapshot.hasError) return Text(snapshot.error);
              return snapshot.hasData
                  ? _buildProvider(snapshot.data)
                  : Center(child: CircularProgressIndicator(),);
            },
          ),
        ),
        Container(
          height: 200,
          child: FutureBuilder<List<LocaleChoice>>(
            future: _localeFuture,
            builder: (context, snapshot){
              if(snapshot.hasError) return Text(snapshot.error);
              return snapshot.hasData
                  ? _getLocaleFromDb(snapshot.data)
                  : Center(child: CircularProgressIndicator(),);
            }
          ),
        )
      ],
    );
  }

  Widget _getLocaleFromDb(List<LocaleChoice> _localeList){
    return FutureBuilder<Setting>(
        future: _settingFuture,
        builder: (context, snapshot){
          if(snapshot.hasError) return Text(snapshot.error);
          return snapshot.hasData
              ? _buildLocale(_localeList, snapshot.data)
              : Center(child: CircularProgressIndicator(),);
        }
    );
  }

  void _saveInDb(LocaleChoice _loc){
    _stateCheck ++;
    SQLiteDbProvider.db.insertSetting(
      Setting(
         'locale',
        _loc.fullLocale,
        DateTime.now(),
      )
    );
    AppBuilder.of(context).rebuild();
  }

  Widget _buildLocale(List<LocaleChoice> _localeList, Setting _setting){
    if(_setting.attribute != null && _stateCheck == 0) {
      for(int i = 0; i<_localeList.length; i++){
        if(_localeList[i].fullLocale == _setting.attribute){
          _indexSelected = i;
          break;
        }
      }
    }
    return ListView.builder(
      itemCount: _localeList.length,
        itemBuilder: (BuildContext context, int index){
        LocaleChoice _locale = _localeList[index];
        return Card(
          child: ListTile(
            leading: Text(_locale.isoCode),
            title: Text(_locale.country),
            subtitle: ChoiceChip(
              label: Icon(Icons.check_box),
              selected: _indexSelected == index,
              selectedColor: Colors.greenAccent,
              backgroundColor: Colors.black87,
              onSelected: (value){
                setState(() {
                  _indexSelected = value ? index : -1;
                  if(value) _saveInDb(_locale);
                });
              },
            ),
          ),
        );
        }
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
                    ? _MyProviders(snapshot.data,) // Text(snapshot.data.toString())
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
  _MyProviders(this.providers);

  @override
  _MyProvidersState createState() => _MyProvidersState();
}

class _MyProvidersState extends State<_MyProviders>{
  final mySettings = SettingBloc();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(child:buildProviderList(widget.providers)
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
}

class SwitchBox extends StatefulWidget {
  Setting setting;
  final Provider provider;
  SwitchBox({Key key, this.setting, this.provider});

  @override
  _SwitchBoxState createState() => _SwitchBoxState(setting, provider);
}

class _SwitchBoxState extends State<SwitchBox> {
  Setting setting;
  final Provider provider;
  
  final mySettings = SettingBloc();

  _SwitchBoxState(this.setting, this.provider);

  BuildContext contextG;

  bool _isSwitch;

  @override
  void initState(){
    super.initState();
    _isSwitch = setting.attribute == null ? false : true;
  }

  void _saveInDb(){
    mySettings.add(Setting(
        provider.shortName, 'provider', DateTime.now()
    ));
    SQLiteDbProvider.db.insertSetting(Setting(
        provider.shortName, 'provider', DateTime.now()
    ));
    AppBuilder.of(contextG).rebuild();
  }

  void _setIntensityAsNull() {
    setState(() {
      mySettings.delete(setting.id);
    });
  }

  void _setIntensityAsOne() {
    setState(() {
      _saveInDb();
    });
  }

  @override
  Widget build(BuildContext context) {
    contextG = context;
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