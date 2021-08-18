# releasenote-script

[こういった感じのリリースノート](https://github.com/bu-tokumitsu/releasenote-script/releases/tag/v1.0.0)を作成するシェルスクリプトです


## 動作の際に必要なインストール

バージョンはこのプロジェクトを動作確認した時のバージョンになります

| tools | version |
| --- | --- |
| [GitHub CLI](https://cli.github.com/) | v1.9.2 | 
| [jq](https://stedolan.github.io/jq/download/) | v1.5 |

## リリースノート生成スクリプト実行

```
ex) $ sh ./githubRelease.sh "Milestone1" v1.0.0
$ sh ./githubRelease.sh ${MILESTONE_NAME} ${RELEASE_VERSION}
```
