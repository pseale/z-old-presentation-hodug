using NUnit.Framework;

namespace DemoWebApp.Tests
{
    [TestFixture]
    public class DemoTests
    {
        [Test]
        public void TestWillPass()
        {
            Assert.AreEqual(1, 1);  //most excellent test ever
        }

        [Test]
        [Ignore]
        public void TestWillFAIL()
        {
            Assert.AreEqual(1, 2);  //TODO: implement test. Check in now and fix later! Good idea.
        }
    }
}