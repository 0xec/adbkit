Stream = require 'stream'
Sinon = require 'sinon'
Chai = require 'chai'
Chai.use require 'sinon-chai'
{expect} = require 'chai'

Parser = require '../../src/adb/parser'

describe 'Parser', ->

  describe 'readBytes(howMany, callback)', ->

    it "should read as many bytes as requested", (done) ->
      stream = new Stream.PassThrough
      parser = new Parser stream
      parser.readBytes 4, (buf) ->
        expect(buf.length).to.equal 4
        expect(buf.toString()).to.equal 'OKAY'
        parser.readBytes 2, (buf) ->
          expect(buf).to.have.length 2
          expect(buf.toString()).to.equal 'FA'
          done()
      stream.write 'OKAYFAIL'

  describe 'readAscii(howMany, callback)', ->

    it "should read as many ascii characters as requested", (done) ->
      stream = new Stream.PassThrough
      parser = new Parser stream
      parser.readAscii 4, (str) ->
        expect(str.length).to.equal 4
        expect(str).to.equal 'OKAY'
        done()
      stream.write 'OKAYFAIL'

  describe 'readValue(callback)', ->

    it "should read a protocol value as a Buffer", (done) ->
      stream = new Stream.PassThrough
      parser = new Parser stream
      parser.readValue (value) ->
        expect(value).to.be.an.instanceOf Buffer
        expect(value).to.have.length 4
        expect(value.toString()).to.equal '001f'
        done()
      stream.write '0004001f'

    it "should return an empty value", (done) ->
      stream = new Stream.PassThrough
      parser = new Parser stream
      parser.readValue (value) ->
        expect(value).to.be.an.instanceOf Buffer
        expect(value).to.have.length 0
        done()
      stream.write '0000'

  describe 'readError(callback)', ->

    it "should read a value as an Error", (done) ->
      stream = new Stream.PassThrough
      parser = new Parser stream
      parser.readError (err) ->
        expect(err).to.be.an.instanceOf Error
        expect(err.message).to.equal 'epic failure'
        done()
      stream.write '000cepic failure'

  describe 'unbind()', ->

    it "should unbind the parser from the stream", (done) ->
      stream = new Stream.PassThrough
      parser = new Parser stream
      spy = Sinon.spy()
      parser.readValue spy
      parser.unbind()
      stream.write 'OKAYFAIL'
      setTimeout ->
        expect(spy).to.not.have.been.called
        done()
      , 50

  it "should wait for enough data to appear", (done) ->
    stream = new Stream.PassThrough
    parser = new Parser stream
    parser.readBytes 5, (buf) ->
      expect(buf.toString()).to.equal 'BYTES'
      done()
    setTimeout ->
      stream.write 'BYTES'
    , 50

  it "should pause stream when nothing has been requested", (done) ->
    stream = new Stream.PassThrough
    parser = new Parser stream
    stream.write 'FOO'
    setTimeout ->
      parser.readBytes 2, (buf) ->
        expect(buf.length).to.equal 2
        expect(buf.toString()).to.equal 'FO'
        done()
    , 50
