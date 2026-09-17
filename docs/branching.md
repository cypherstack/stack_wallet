# Branches

Three branches, each with one job.

| Branch | What it is for |
| --- | --- |
| `dev` | Where work lands. Push freely. Debug builds come from here. |
| `main` | Default branch and the public face. Only ever receives a merge from `dev`. Releases are tagged here. |
| `upstream-sync` | Only ever merges `cypherstack/stack_wallet`, so an upstream merge is reviewed on its own before it reaches `dev`. |

`staging` is kept for now because it was the default until 17 September 2026
and people have clones pointing at it. It will be retired once that has been
said out loud to the community.

## Why main and not staging

The fork inherited `staging` as its default from Stack Wallet, whose default
branch is also `staging`. That was invisible while nobody forked us. It stopped
being invisible once people started forking this repo rather than Stack Wallet:
whoever clones us lands on the default branch, and a branch called `staging`
tells them they are not on the stable one.

At the switch, `main` held nothing that `staging` did not. It was 179 commits
behind and had not moved since 9 July, and no release tag had ever pointed at
it, so moving the default cost nothing and lost nothing.

## Releasing

Releases are cut from `main`, not from every fix. That is the point of the
arrangement: a day of bug fixes and interface work is one merge and one tag
rather than a version number per commit.

Build and sign locally, by hand. See `scripts/build-android-docker.sh` and the
notes in `.github/workflows/build.yaml` about why CI cannot publish.

## Upgrade safety

Anything released from `main` installs over an existing wallet without
disturbing it, provided three things hold:

- the application id stays `org.bitfinitechain.wallet`
- the APK is signed with the same key
- the version code only ever goes up (arm64 = BUILD_NUM + 2000)

Check the last one against what is installed before building a release.
Android refuses a downgrade, and the failure reads as a signature error, which
sends you looking in the wrong place.
