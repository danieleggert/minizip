minizip for iOS

Very much work-in-progress.

The `minizip` folder contains the files to use, of which

    miniunz.c
    minizip.mm
    minizip.pc.in

are only for later reference, but are not used. Add the others to your project, then use like this:

    NSDirectoryEnumerator *enumerator; // Assume we have this
    NSURL *outputFileURL; // Assume we have this, too
	
    NSError *error = nil;
    BOMiniZipArchiver *archiver = [[BOMiniZipArchiver alloc] initWithFileURL:outputFileURL append:NO error:&error];
    NSAssert(archiver != nil, @"%@", error);
    
    for (NSURL *fileURL in enumerator) {
        NSAssert([archiver appendFileAtURL:fileURL error:&error], @"%@", error);
    }
    
    NSAssert([archiver finishEncoding:&error], @"%@", error);
