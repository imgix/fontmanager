all: release

release:
	xcodebuild -configuration Release

debug:
	xcodebuild -configuration Debug

clean:
	xcodebuild clean

.PHONY: all release debug clean
