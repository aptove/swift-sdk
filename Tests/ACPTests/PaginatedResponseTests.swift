
        let count = await fetchCount.get()
        XCTAssertEqual(count, 1)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 1)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 3)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 0)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 1)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 1)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 2)

        
        let count = await fetchCount.get()
        XCTAssertEqual(count, 1)