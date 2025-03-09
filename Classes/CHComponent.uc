class CHComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var int mNumberOfFiles;
var SharedCloudFileInterface mCachedSharedCloudInterface;

struct MutatorData
{
	var string Title;//Workshop mod name
	var string ID;//Workshop mod ID
};
var int mPressCount;

var array<string> mPublishedHandles;
var array<MutatorData> mAllModMutators;
var array<ModInfoStruct> mAvailableModMutators;

function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	//local int i;

	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		GetAllModMutators();
		GetAvailableMutators();
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Right", string( newKey ) ) || newKey == 'XboxTypeS_A')
		{
			mPressCount++;
		}

		if( localInput.IsKeyIsPressed( "GBA_Back", string( newKey ) ) || newKey == 'XboxTypeS_B')
		{
			mPressCount++;
		}

		if( localInput.IsKeyIsPressed( "GBA_Left", string( newKey ) ) || newKey == 'XboxTypeS_X')
		{
			mPressCount++;
		}

		if(mPressCount >= 3)
		{
			myMut.SetTimer(2.f, false, NameOf(ShowHelp), self);
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Forward", string( newKey ) ) || newKey == 'XboxTypeS_A'
		|| localInput.IsKeyIsPressed( "GBA_Back", string( newKey ) ) || newKey == 'XboxTypeS_B'
		|| localInput.IsKeyIsPressed( "GBA_Left", string( newKey ) ) || newKey == 'XboxTypeS_X'
		|| localInput.IsKeyIsPressed( "GBA_Right", string( newKey ) ) || newKey == 'XboxTypeS_Y')
		{
			mPressCount=0;
			if(myMut.IsTimerActive(NameOf(ShowHelp), self))
			{
				myMut.ClearTimer(NameOf(ShowHelp), self);
			}
		}
	}
}

function ShowHelp()
{
	local array<string> usedMutatorNames;
	local array<string> possibleNames;
	local array<string> alreadyTestedMods;
	local array<string> modIDsToOpen;
	local string workString;
	local int i, j, k;
	local bool modFound;
	local string urlToOpen;
	local bool collectionAdded;

	 if(mAllModMutators.Length == 0)
	 {
	 	myMut.WorldInfo.Game.Broadcast(myMut, "No downloaded or published mutator found.");
	 	return;
	 }

	GetUsedMutators(usedMutatorNames);//GeneosisMod.TheMod
	for(i=0 ; i<usedMutatorNames.Length ; i++)
	{
		modFound=false;
		GetAllPossibleModNames(usedMutatorNames[i], possibleNames);
		if(alreadyTestedMods.Find(possibleNames[0]) != INDEX_NONE)
			continue;

		alreadyTestedMods.AddItem(possibleNames[0]);
		for(j=0 ; j<mAllModMutators.Length && !modFound ; j++)
		{
			workString=NormalizeName(mAllModMutators[j].Title);
			for(k=0 ; k<possibleNames.Length && !modFound ; k++)
			{
				if(InStr(workString, possibleNames[k]) != INDEX_NONE
				|| InStr(possibleNames[k], workString) != INDEX_NONE)
				{
					//myMut.WorldInfo.Game.Broadcast(myMut, "Mutator Found!" @ mAllModMutators[j].Title);
					modIDsToOpen.AddItem(mAllModMutators[j].ID);
					modFound=true;
				}
			}
		}

		if(!modFound && !collectionAdded && InStr(possibleNames[0], "GENEOSIS") != INDEX_NONE)//if mod not found, open collection
		{
			modIDsToOpen.AddItem("248378540");
			collectionAdded=true;
		}
	}

	if(modIDsToOpen.Length == 0)
	{
		myMut.WorldInfo.Game.Broadcast(myMut, "Mutators used not found on the workshop.");
		return;
	}

	urlToOpen="javascript:{";
	for(i=0 ; i<modIDsToOpen.Length ; i++)
	{
		BuildURLString(urlToOpen, modIDsToOpen[i]);
	}
	urlToOpen$="window.close();}";
	//myMut.WorldInfo.Game.Broadcast(myMut, "_FinalURL=" $ urlToOpen);
	OpenWorkshopTab(urlToOpen);
}
/*
	urlToOpen="https://www.google.com/search?q=site%3Ahttps%3A%2F%2Fsteamcommunity.com";
	for(i=0 ; i<modIDsToOpen.Length ; i++)
	{
		BuildURLString(urlToOpen, modIDsToOpen[i], i==0);
	}
	OpenWorkshopTab(urlToOpen);

function BuildURLString(out string urlToOpen, string modID, bool isFirst)
{
	urlToOpen$=isFirst?"":"%20OR";
	urlToOpen$="%20id%3D" $ modID;
}
*/

function GetAllPossibleModNames(string FileName, out array<string> allNames)
{
	local int i;
	local array<string> splittedName;

	splittedName=SplitString(FileName, ".");
	allNames.Length=0;
	allNames.AddItem(NormalizeName(splittedName[0]));
	for(i=0 ; i<mAvailableModMutators.Length ; i++)
	{
		if(InStr(mAvailableModMutators[i].FileName, splittedName[0]) != INDEX_NONE)
		{
			allNames.AddItem(NormalizeName(Split(mAvailableModMutators[i].FileName, ".", true)));
			allNames.AddItem(NormalizeName(mAvailableModMutators[i].DisplayName));
		}
	}
}

function BuildURLString(out string urlToOpen, string modID)
{
	urlToOpen$="window.open('http://steamcommunity.com/sharedfiles/filedetails/?id=" $ modID $ "','_blank');";
}

function string NormalizeName(string newName)
{
	return Caps(Repl(Repl(Repl(Repl(newName, "_", ""), ".", ""), " ", ""), "-", ""));
}

function OpenWorkshopTab(string urlToOpen)
{
	local OnlineUIInterface UIInterface;

	UIInterface = class'GameEngine'.static.GetOnlineSubsystem().UIInterface;

	if(UIInterface != none)
	{
		//myMut.WorldInfo.Game.Broadcast(myMut, "FinalURL=" $ urlToOpen);
		UIInterface.OpenWebURL(urlToOpen);
	}
}

function GetUsedMutators(out array<string> usedMutatorNames)
{
	local GGGameViewportClient viewport;
	local int i;
	//myMut.WorldInfo.Game.Broadcast(myMut, "GetUsedMutators");
	viewport = class'GGGameViewportClient'.static.GetViewportClient();
	for(i=0 ; i<viewport.mMutatorMap.Length ; i++)
	{
		if(viewport.mMutatorMap[i].PlayerSlots.Find(gMe.mCachedSlotNr) != INDEX_NONE)
		{
			if(InStr(viewport.mMutatorMap[i].MutatorName, string(myMut.class)) != INDEX_NONE)//Ignore this mod
				continue;

			usedMutatorNames.AddItem(viewport.mMutatorMap[i].MutatorName);
			//myMut.WorldInfo.Game.Broadcast(myMut, viewport.mMutatorMap[i].MutatorName);
		}
	}
}

function GetAllModMutators()
{
	local GGWorkshop workshop;
	local int i;
	local MutatorData newMutData;

	//myMut.WorldInfo.Game.Broadcast(myMut, "All mutators:");
	mAllModMutators.Length=0;
	mPublishedHandles.Length=0;
	if(mCachedSharedCloudInterface == none)
	{
		mCachedSharedCloudInterface = class'GameEngine'.static.GetOnlineSubsystem().SharedCloudInterface;
	}
	//Get downloaded mods
	workshop = class'GGGameViewportClient'.static.GetViewportClient().mWorkshop;
	for(i=0 ; i<workshop.mUGCDetails.Length ; i++)
	{
		newMutData.Title=workshop.mUGCDetails[i].Title;
		newMutData.ID=workshop.mUGCDetails[i].PublishHandle;
		mAllModMutators.AddItem(newMutData);
	}
	//Get my mods
	mCachedSharedCloudInterface.AddEnumerateUserPublishedFilesCompleteDelegate( OnEnumerateUserPublishedFilesComplete );
	mCachedSharedCloudInterface.EnumerateUserPublishedFiles();
}

function OnEnumerateUserPublishedFilesComplete(bool bWasSuccessful, int NumResultsReturned, int TotalResultCount, out array<string> PublishedHandles)
{
	local int i;

	mCachedSharedCloudInterface.ClearEnumerateUserPublishedFilesDelegate( OnEnumerateUserPublishedFilesComplete );
	//Merge the two lists
	for( i = 0; i < PublishedHandles.Length; i++ )
	{
		mPublishedHandles.AddItem(PublishedHandles[i]);
	}

	if( mPublishedHandles.Length > 0 )
	{
		mCachedSharedCloudInterface.AddGetPublishedFileDetailsCompleteDelegate( OnGetPublishedFileDetailsComplete );
	}

	mNumberOfFiles = mPublishedHandles.Length;
	for( i = 0; i < mPublishedHandles.Length; i++ )
	{
		mCachedSharedCloudInterface.GetPublishedFileDetails( mPublishedHandles[i] );
	}
}

function OnGetPublishedFileDetailsComplete(bool bWasSuccessful, string FileHandle, bool FileWasNotFound, int UpdatedTime, string FileName, string PublishHandle, string Title )
{
	local MutatorData newMutData;

	if(mAllModMutators.Find('Title', Title) == INDEX_NONE)
	{
		newMutData.Title=Title;
		newMutData.ID=PublishHandle;
		mAllModMutators.AddItem(newMutData);
		//myMut.WorldInfo.Game.Broadcast(myMut, Title @ newMutData.ID);
	}

	mNumberOfFiles--;
	if(mNumberOfFiles <= 0)
	{
		mCachedSharedCloudInterface.ClearGetPublishedFileDetailsDelegate( OnGetPublishedFileDetailsComplete );
	}
}

function GetAvailableMutators()
{
	local GGDownloadableContentManager DLCManager;

	DLCManager = GGDownloadableContentManager( class'GameEngine'.static.GetDLCManager() );
	DLCManager.GetAvailableMutators( mAvailableModMutators );
}

defaultproperties
{

}