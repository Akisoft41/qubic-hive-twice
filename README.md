# qubic-hive-twice
Intégration de Qubic dans un *Custom Miner HiveOS*, pour miner en même temps avec le CPU et les GPU

web : https://web.qubic.li/

wallet : https://wallet.qubic.li/

pool : https://app.qubic.li/public

miner : https://github.com/qubic-li/client?tab=readme-ov-file#download

![Overview](/img/overview.png)

## Préparation HiveOS

Pour pouvoir exécuter le miner Quibic, il faut la version beta de HiveOS.

```
hive-replace --list
2   ## beta ##
```

Pour améliorer (un peut) le minage avec le CPU, il faut définir des *huge pages* :
```
/usr/sbin/sysctl -w vm.nr_hugepages=832
```
Le nombre dépend du nombre de trheds: nb_threads * 52 (exemple 16 * 52 = 832).


## Flight Sheet

Voici ma Flight Sheet:

![Flight Sheet](/img/FlightSheet1.png)

Le script de démarrage prend les valeurs de la flight sheet pour compléter la config par défaut (`appsettings_global.json`).

A chaque démarrage du miner, le fichier `appsettings.json` est recréé, et 2 instance du miner sont exécutées.

### Miner name

Ne pas modifier ce champ, il est rempli automatiquement avec l'installation URL.

### Installation URL

`https://github.com/Akisoft41/qubic-hive-twice/releases/download/v1.8.9/qubic-hive-twice-1.8.9.tar.gz`

### Hash algorithm:

Ce champ n'est pas utilisé, on peut laisser `----`

### Wallet and worker template:

Nom du worker. Valeur de `"alias"` dans appsettings.json

pour le minage CPU, le préfixe `-cpu` est ajouté au nom du worker.

### Pool URL:

Valeur de `"baseUrl"` dans appsettings.json

`https://mine.qubic.li/` pour la pool `app.qubic.li`

### Pass:

Pas utilisé.

### Extra config arguments:

Chaque ligne (sprarées par un `CR`) est fusionnée dans `appsettings.json`

- Pour les OC, on peut mettre directement une ligne pour la commande `nvtool`

- Ajouter une ligne `"amountOfThreads": n` (remplacer *n* par le nombre de threads)

- Il faut une des lignes
  - `"payoutId": "_ton_payout_id_"` ou 
  - `"accessToken": "_ton_access_token_"`



## Flight Sheet avancée

Voici ma Flight Sheet pour utiliser aussi la pool publique:

![Flight Sheet](/img/FlightSheet2.png)

### Extra config arguments:

- Il est possible de mettre un commentaire en commençant la ligne par un `#`.

- Pour appliquer une ligne que pour un miner, il faut commencer la ligne par `cpu:` ou `gpu:`.

Dans mon exemple, j'utilise un `accessToken` pour le minage GPU, et un `payoutId` pour le minage CPU sur la pool publique.


## Configuration par défaut

### CPU
```
  "Settings": {
    "baseUrl": "https://mine.qubic.li/",
    "amountOfThreads": 1,
    "payoutId": null,
    "accessToken": null,
    "alias": "qubic.li Client-cpu",
    "allowHwInfoCollect": false
  }
```

### GPU
```
  "Settings": {
    "baseUrl": "https://mine.qubic.li/",
    "payoutId": null,
    "accessToken": null,
    "alias": "qubic.li Client",
    "allowHwInfoCollect": true,
    "overwrites": {"CUDA": "12"}
  }
```


## Que contient l'archive tar.gz ?

Dans cette archive, j'ai développé 3 script bash : h-config.sh, h-run.sh et h-stats.sh

Il y a aussi le programme officiel de Qubic : qli-Client

______________

Ce projet est Open Source sous licence GPL-3.0-or-later

Copyright (C) 2024 Pascal Akermann
