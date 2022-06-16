import 'dart:async';

import 'package:flutter/material.dart';
import 'package:justwatch_but_faster/main.dart';
import 'package:justwatch_but_faster/models/locale_choice.dart';
import 'package:justwatch_but_faster/models/setting.dart';
import 'package:justwatch_but_faster/models/provider.dart';
import 'package:justwatch_but_faster/services/fetch_service.dart';
import 'package:justwatch_but_faster/services/sql_db_provider.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late Future<List<Provider>> _providersFuture;
  late Future<List<LocaleChoice>> _localeFuture;
  late Future<Setting> _settingFuture;

  int _indexSelected = 0;
  int _stateCheck = 0;

  @override
  void initState(){
    super.initState();

    _providersFuture = fetchProvider();
    _localeFuture = fetchLocale();
    _settingFuture = SQLiteDbProvider().getSettingById('locale');
  }

  @override
  Widget build(BuildContext context){
    return Column(
      children: <Widget>[
        Expanded(
          child: FutureBuilder<List<Provider>>(
            future: _providersFuture,
            builder: (context, snapshot){
              if (snapshot.hasError) {
                return Text("Something went wrong ${snapshot.error}");
              }
              if (snapshot.hasData){
                return _buildProvider(snapshot.data ?? []);
              } else {
                return const Center(child: CircularProgressIndicator(),);
              }
            },
          ),
        ),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<LocaleChoice>>(
            future: _localeFuture,
            builder: (context, snapshot){
              if(snapshot.hasError) {
                return Text("Something went wrong ${snapshot.error}");
              }
              if(snapshot.hasData){
                return _getLocaleFromDb(snapshot.data ?? []);
              }
              return const Center(child: CircularProgressIndicator(),);
            }
          ),
        )
      ],
    );
  }

  Widget _getLocaleFromDb(List<LocaleChoice> localeList){
    return FutureBuilder<Setting>(
        future: _settingFuture,
        builder: (context, snapshot){
          if(snapshot.hasError) {
            return Text("Something went wrong ${snapshot.error}");
          }

          return snapshot.hasData
              ? _buildLocale(localeList, snapshot.data!)
              : const Center(child: CircularProgressIndicator(),);
        }
    );
  }

  void _saveInDb(LocaleChoice loc){
    _stateCheck ++;
    SQLiteDbProvider().insertSetting(
      Setting(
         'locale',
        loc.fullLocale ?? 'en',
        DateTime.now(),
      )
    );
    AppBuilder.of(context)!.rebuild();
  }

  Widget _buildLocale(List<LocaleChoice> _localeList, Setting _setting){
    if(_stateCheck == 0) {
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
            leading: Text("${_locale.isoCode}"),
            title: Text("${_locale.country}"),
            subtitle: ChoiceChip(
              label: _indexSelected == index ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
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
            leading: Image.network("https://images.justwatch.com${_provTemp.iconUrl}"),
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
      future: SQLiteDbProvider().getSettingById(_provTemp.shortName, attribute: "empty"),
        builder: (context, snapshot){
        if(snapshot.hasError) return Text("Something went wrong ${snapshot.error}");
        return snapshot.hasData
            ? SwitchBox(setting: snapshot.data!, provider: _provTemp,) //Text(snapshot.data.id)
            : const Center(child: CircularProgressIndicator(),);
        }
    );
  }
}

class _MyProviders extends StatefulWidget{
  final List<Provider> providers;
  const _MyProviders(this.providers);

  @override
  _MyProvidersState createState() => _MyProvidersState();
}

class _MyProvidersState extends State<_MyProviders>{

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
    return
      ListView.builder(
      padding: const EdgeInsets.all(8),
        itemCount: _providerList.length,
      itemBuilder: (BuildContext context, int index){
        return Text(_providerList[index].shortName); // _cardProvider(_providerList[index]); //  Text(_providerList[index].shortName);
      },
    );
  }
}

class SwitchBox extends StatefulWidget {
  final Setting setting;
  final Provider provider;
  const SwitchBox({
    Key? key, required this.setting, required this.provider}):super(key: key);

  @override
  State<SwitchBox> createState() => _SwitchBoxState();
}

class _SwitchBoxState extends State<SwitchBox> {

  bool _isSwitch = false;

  @override
  void initState(){
    super.initState();
    _isSwitch = widget.setting.attribute == "empty" ? false : true;
  }

  void _saveInDb(){
    SQLiteDbProvider().insertSetting(Setting(
        widget.provider.shortName, 'provider', DateTime.now()
    ));
    AppBuilder.of(context)?.rebuild();
  }

  void _deleteSetting() async{
    SQLiteDbProvider().deleteSetting(widget.setting.id);
    print((await SQLiteDbProvider().getSettingById(widget.setting.id)).attribute);
    AppBuilder.of(context)?.rebuild();
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
          value: _isSwitch,
          onChanged: (value) {
            setState(() {
              _isSwitch = value;
              value ? _saveInDb() : _deleteSetting();
            });
          },
    );
  }
}
