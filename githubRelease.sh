#!/bin/sh

# リポジトリ情報
owner="bu-tokumitsu"
repository="releasenote-script"
repo="${owner}/${repository}"

# 実行ブランチ
releaseBranch="main"
branch=$(git rev-parse --abbrev-ref @)
if [ $releaseBranch != $branch ]; then
    echo "
    ${releaseBranch}ブランチで実行してください
    "
    exit 1
fi

# 引数1: マイルストーン名、 引数2: アプリバージョン
milestoneName=$1
appVersion=$2
filterLabel="sprint-feature"

if [ -z "$milestoneName" ] || [ -z "$appVersion" ]; then
    echo "
    引数が足りません
    1:マイルストーン名 => $milestoneName
    2:リリースバージョン => $appVersion
    "
    exit 1
else
    echo "
    ${milestoneName} (${appVersion}) のリリース開始
    "
fi


# Issues
issuesJson=$(gh issue list -R ${repo} --search "milestone:${milestoneName}" -s "closed" --json "number,title,url,labels")
# Issueの中でもスプリント対応（追加機能）として起票されたIssueのみをまとめる
mainIssues=$(echo $issuesJson | jq -r 'sort_by(.number) | map(select(.labels[].name == "'$filterLabel'")) | .[] | "* [\(.title)](\(.url))" | @text')
# その他のIssues
otherIssuesFilter=$(echo $issuesJson | jq -r 'sort_by(.number) | map(select(.labels[].name != "'$filterLabel'"))')
otherIssuesCnt=$(echo $otherIssuesFilter | jq -r 'length')
otherIssues=$(echo $otherIssuesFilter | jq -r '.[] | "* [\(.title)](\(.url))" | @text')

# PullRequests
prJson=$(gh pr list -R ${repo} --search "milestone:${milestoneName}" -s "closed" --json "number,title,url")
prCnt=$(echo $prJson | jq -r 'length')
prText=$(echo $prJson | jq -r 'sort_by(.number) | .[] | "* [\(.title)](\(.url))" | @text')

# リリースノート
# タイトル
releaseTitle="${milestoneName} リリース"
# 本文
mainRelText="# 主な変更点\n\n${mainIssues}\n\n"
otherRelText="<details>\n<summary>その他のIssuesを表示（${otherIssuesCnt}）</summary>\n\n${otherIssues}\n</details>\n\n"
prRelText="<details>\n<summary>PullRequestsを表示（${prCnt}）</summary>\n\n${prText}\n</details>\n\n"
releaseBody=$(echo "${mainRelText}${otherRelText}${prRelText}")


# タグ登録(直近のタグに同名のものがあれば削除して付け直し)
latestTag=$(git describe --abbrev=0)
if [ $latestTag = $appVersion ]; then
    echo "
    ${latestTag} タグが既に登録されているので付け直しの為、一度削除します
    "
    git tag -d $latestTag
    git push -d origin $latestTag
fi
echo "
    ${appVersion} タグを登録します
"
git tag -a $appVersion -m "${milestoneName}リリース"
git push --tags

# リリースノート
latestReleaseInfo=$(gh release list -R ${repo} -L 1)
if [[ $latestReleaseInfo =~ $appVersion ]]; then
    echo "
    ${latestReleaseInfo}
    が既に登録されているので削除します
    "
    gh release delete -R $repo $appVersion -y 
fi
echo "
    ${releaseTitle} を登録します
"
resultUrl=$(gh release create -R $repo $appVersion -t "${releaseTitle}" -n "${releaseBody}")

echo "
    ${milestoneName} (${appVersion}) のリリース完了

    ${resultUrl}
"
